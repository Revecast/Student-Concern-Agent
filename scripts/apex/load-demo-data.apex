/*****************************************************************
Name:          load-demo-data.apex  (anonymous Apex, run by scripts/load-demo-data.sh)
============================================================
Purpose:       Loads the Student Concern demo cohort (SCA-8): Jordan Rivera
               plus 20 other fictional first-year students, with term
               enrollment (Freshman, Active), three course sections,
               attendance for the last 14 days, simulated classroom activity
               and an Advisee Record whose case team is the assigned advisor.

               Idempotent: every record is matched on a stable key (email,
               name or external key) and updated in place, and every date is
               relative to today, so running it again resets the scenario
               ("Jordan stops logging in and misses two classes") without
               creating duplicates. It never deletes anything.

               Expected nightly scores (Risk Score Setting defaults):
               Jordan 7 (2 absences = 4, 5 days without login = 3);
               Avery 5, Riley 4, Quinn 4, Taylor 2, Morgan 3, Casey 3,
               everyone else 0. Only Jordan reaches the alert limit of 6.

               All people are fictional. No real student data is used.
============================================================
History
-------
VERSION  AUTHOR                 DATE         DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026   Created   SCA-8
*****************************************************************/

// ---- Settings -------------------------------------------------------------
// Username of the demo advisor (assigned advisor for every demo student).
// Default: the presenter. Change here to use a different advisor user.
String ADVISOR_USERNAME = 'ernie.maldonado@revecast.io.edupde';
String KEY_PREFIX = 'DEMO';                       // prefix for every demo key
String EMAIL_DOMAIN = 'student.jaxstate.example'; // reserved domain: never delivers
Date TODAY_DATE = Date.today();
Datetime NOW_TIME = Datetime.now();

// ---- Cohort definition ----------------------------------------------------
// Each row: key, first, last, absences in the last 14 days,
// days since last login, [current grade, grade two weeks ago] for the
// three courses (BIO 101, ENG 101, MATH 110).
List<List<Object>> cohort = new List<List<Object>>{
    new List<Object>{'JORDAN', 'Jordan', 'Rivera', 2, 5, new List<Decimal>{84, 86, 81, 83, 88, 88}},
    new List<Object>{'AVERY',  'Avery',  'Chen',    0, 11, new List<Decimal>{79, 79, 85, 85, 77, 78}},
    new List<Object>{'RILEY',  'Riley',  'Patel',   2, 1, new List<Decimal>{88, 88, 91, 90, 84, 85}},
    new List<Object>{'QUINN',  'Quinn',  'Okafor',  1, 2, new List<Decimal>{77, 81, 86, 86, 90, 90}},
    new List<Object>{'TAYLOR', 'Taylor', 'Brooks',  1, 2, new List<Decimal>{92, 92, 88, 87, 85, 85}},
    new List<Object>{'MORGAN', 'Morgan', 'Silva',   0, 6, new List<Decimal>{83, 83, 79, 79, 86, 85}},
    new List<Object>{'CASEY',  'Casey',  'Nguyen',  0, 1, new List<Decimal>{65, 66, 72, 73, 75, 74}},
    new List<Object>{'ALEX',   'Alex',   'Romero',  0, 1, new List<Decimal>{90, 89, 93, 92, 88, 88}},
    new List<Object>{'SAM',    'Sam',    'Kowalski',0, 2, new List<Decimal>{86, 85, 82, 82, 79, 79}},
    new List<Object>{'JAMIE',  'Jamie',  'Haddad',  0, 1, new List<Decimal>{94, 94, 91, 91, 96, 95}},
    new List<Object>{'DREW',   'Drew',   'Mensah',  0, 3, new List<Decimal>{81, 81, 84, 83, 78, 78}},
    new List<Object>{'PAT',    'Pat',    'Lindqvist',0, 1, new List<Decimal>{88, 87, 85, 86, 89, 89}},
    new List<Object>{'REESE',  'Reese',  'Tanaka',  0, 2, new List<Decimal>{76, 76, 82, 81, 80, 80}},
    new List<Object>{'SKYLER', 'Skyler', 'Adeyemi', 0, 1, new List<Decimal>{91, 90, 87, 87, 92, 92}},
    new List<Object>{'ROWAN',  'Rowan',  'Garcia',  0, 1, new List<Decimal>{84, 84, 88, 88, 83, 82}},
    new List<Object>{'EMERY',  'Emery',  'Walsh',   0, 2, new List<Decimal>{79, 78, 81, 81, 85, 85}},
    new List<Object>{'HAYDEN', 'Hayden', 'Kim',     0, 1, new List<Decimal>{87, 87, 90, 89, 86, 86}},
    new List<Object>{'LOGAN',  'Logan',  'Petrov',  0, 3, new List<Decimal>{82, 82, 77, 77, 84, 84}},
    new List<Object>{'PARKER', 'Parker', 'Diallo',  0, 1, new List<Decimal>{93, 93, 89, 89, 91, 90}},
    new List<Object>{'BLAKE',  'Blake',  'Moreau',  0, 2, new List<Decimal>{78, 77, 83, 83, 80, 80}},
    new List<Object>{'CAMERON','Cameron','Iyer',    0, 1, new List<Decimal>{85, 85, 86, 85, 88, 88}}
};
List<String> courseCodes = new List<String>{'BIO-101', 'ENG-101', 'MATH-110'};
List<String> courseNames = new List<String>{
    'BIO 101 - Introduction to Biology',
    'ENG 101 - College Writing',
    'MATH 110 - College Algebra'
};
// Each course met 4 times in the last 14 days (days ago). Absences are the
// most recent sessions of BIO 101 first, then ENG 101.
List<Integer> sessionDaysAgo = new List<Integer>{2, 4, 9, 11};

// ---- Advisor ----------------------------------------------------------------
User advisor = [SELECT Id FROM User WHERE Username = :ADVISOR_USERNAME AND IsActive = true LIMIT 1];
CaseTeamRole advisorRole = [SELECT Id FROM CaseTeamRole WHERE Name = 'Advisor' LIMIT 1];
Id adviseeRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
    .get('Advisee_Record').getRecordTypeId();

// ---- Term, courses and sections (match on Name) -----------------------------
String termName = KEY_PREFIX + ' Fall 2026';
List<AcademicTerm> terms = [SELECT Id FROM AcademicTerm WHERE Name = :termName LIMIT 1];
AcademicTerm term = terms.isEmpty() ? new AcademicTerm(Name = termName) : terms[0];
term.StartDate = Date.newInstance(2026, 8, 24);
term.EndDate = Date.newInstance(2026, 12, 18);
upsert term;

Map<String, Learning> learningByName = new Map<String, Learning>();
for (Learning existing : [SELECT Id, Name FROM Learning WHERE Name IN :courseNames]) {
    learningByName.put(existing.Name, existing);
}
for (String courseName : courseNames) {
    if (!learningByName.containsKey(courseName)) {
        learningByName.put(courseName, new Learning(Name = courseName, Type = 'LearningCourse',
            AcademicLevel = 'Undergraduate', IsActive = true, Status = 'Published'));
    }
}
upsert learningByName.values();

Map<String, LearningCourse> courseByName = new Map<String, LearningCourse>();
for (LearningCourse existing : [SELECT Id, Name FROM LearningCourse WHERE Name IN :courseNames]) {
    courseByName.put(existing.Name, existing);
}
for (Integer i = 0; i < courseNames.size(); i++) {
    if (!courseByName.containsKey(courseNames[i])) {
        courseByName.put(courseNames[i], new LearningCourse(Name = courseNames[i],
            LearningId = learningByName.get(courseNames[i]).Id, CourseNumber = courseCodes[i]));
    }
}
upsert courseByName.values();

// Section names carry the demo prefix so they never collide with real sections.
Map<String, CourseOffering> sectionByCode = new Map<String, CourseOffering>();
List<String> sectionNames = new List<String>();
for (String code : courseCodes) {
    sectionNames.add(KEY_PREFIX + ' ' + code + ' Fall 2026');
}
for (CourseOffering existing : [SELECT Id, Name FROM CourseOffering WHERE Name IN :sectionNames]) {
    sectionByCode.put(existing.Name.substringBetween(KEY_PREFIX + ' ', ' Fall'), existing);
}
for (Integer i = 0; i < courseCodes.size(); i++) {
    if (!sectionByCode.containsKey(courseCodes[i])) {
        sectionByCode.put(courseCodes[i], new CourseOffering(Name = sectionNames[i],
            LearningCourseId = courseByName.get(courseNames[i]).Id, SectionNumber = '001', IsActive = true,
            StartDate = Datetime.newInstance(2026, 8, 24, 9, 0, 0), EndDate = Datetime.newInstance(2026, 12, 18, 17, 0, 0)));
    }
}
upsert sectionByCode.values();

// ---- Students: one administrative Account + Contact each (match on email) ---
Set<String> emails = new Set<String>();
for (List<Object> row : cohort) {
    emails.add(((String) row[1]).toLowerCase() + '.' + ((String) row[2]).toLowerCase() + '@' + EMAIL_DOMAIN);
}
Map<String, Contact> contactByEmail = new Map<String, Contact>();
for (Contact existing : [SELECT Id, Email, AccountId FROM Contact WHERE Email IN :emails]) {
    contactByEmail.put(existing.Email.toLowerCase(), existing);
}

// Accounts first (one per student, Education Cloud administrative-account model).
Map<String, Account> accountByKey = new Map<String, Account>();
Set<String> accountNames = new Set<String>();
for (List<Object> row : cohort) {
    accountNames.add(KEY_PREFIX + ' - ' + row[1] + ' ' + row[2] + ' Administrative Account');
}
for (Account existing : [SELECT Id, Name FROM Account WHERE Name IN :accountNames]) {
    accountByKey.put(existing.Name, existing);
}
for (String accountName : accountNames) {
    if (!accountByKey.containsKey(accountName)) {
        accountByKey.put(accountName, new Account(Name = accountName,
            Description = 'Fictional demo student (Student Concern Agent, SCA-8).'));
    }
}
upsert accountByKey.values();

List<Contact> students = new List<Contact>();
for (List<Object> row : cohort) {
    String email = ((String) row[1]).toLowerCase() + '.' + ((String) row[2]).toLowerCase() + '@' + EMAIL_DOMAIN;
    Contact student = contactByEmail.containsKey(email) ? contactByEmail.get(email) : new Contact(Email = email);
    student.FirstName = (String) row[1];
    student.LastName = (String) row[2];
    student.AccountId = accountByKey.get(KEY_PREFIX + ' - ' + row[1] + ' ' + row[2] + ' Administrative Account').Id;
    student.Title = 'First-year student';
    student.Description = 'Fictional demo student (Student Concern Agent, SCA-8). Key ' + KEY_PREFIX + '-' + row[0];
    contactByEmail.put(email, student);
    students.add(student);
}
upsert students;

// ---- Term enrollment: Freshman, Active (match on student + term) ----------
// Name is an auto-number on this object, so the natural key is used instead.
Map<Id, AcademicTermEnrollment> enrollmentByStudent = new Map<Id, AcademicTermEnrollment>();
for (AcademicTermEnrollment existing : [SELECT Id, LearnerContactId FROM AcademicTermEnrollment
        WHERE AcademicTermId = :term.Id AND LearnerContactId IN :students]) {
    enrollmentByStudent.put(existing.LearnerContactId, existing);
}
List<AcademicTermEnrollment> enrollments = new List<AcademicTermEnrollment>();
for (Integer i = 0; i < cohort.size(); i++) {
    AcademicTermEnrollment enrollment = enrollmentByStudent.containsKey(students[i].Id)
        ? enrollmentByStudent.get(students[i].Id)
        : new AcademicTermEnrollment(LearnerContactId = students[i].Id, AcademicTermId = term.Id);
    enrollment.EnrollmentStatus = 'Active';
    enrollment.StudyYearClassification = 'Freshman';
    enrollment.EnrollmentReason = 'First Time';
    enrollment.StudentAcademicLevel = 'Undergraduate';
    enrollment.EnrollmentDate = Date.newInstance(2026, 8, 24);
    enrollments.add(enrollment);
}
upsert enrollments;

// ---- Section participants (match on student + section) --------------------
Map<String, CourseOfferingParticipant> participantByKey = new Map<String, CourseOfferingParticipant>();
for (CourseOfferingParticipant existing : [SELECT Id, ParticipantContactId, CourseOfferingId
        FROM CourseOfferingParticipant WHERE ParticipantContactId IN :students]) {
    participantByKey.put(existing.ParticipantContactId + '|' + existing.CourseOfferingId, existing);
}
List<CourseOfferingParticipant> participants = new List<CourseOfferingParticipant>();
for (Integer i = 0; i < cohort.size(); i++) {
    for (String code : courseCodes) {
        Id sectionId = sectionByCode.get(code).Id;
        String participantKey = students[i].Id + '|' + sectionId;
        CourseOfferingParticipant participant = participantByKey.containsKey(participantKey)
            ? participantByKey.get(participantKey)
            : new CourseOfferingParticipant(ParticipantContactId = students[i].Id, CourseOfferingId = sectionId);
        participant.ParticipationStatus = 'Enrolled';
        participant.ParticipantAffiliation = 'Student';
        participant.AcademicTermEnrollmentId = enrollments[i].Id;
        participants.add(participant);
    }
}
upsert participants;

// ---- Attendance: one recording per section meeting, one entry per student ---
// Name is an auto-number, so each recording carries its session key in Comments.
Map<String, AttendanceRecording> recordingByName = new Map<String, AttendanceRecording>();
List<Id> sectionIds = new List<Id>();
for (CourseOffering section : sectionByCode.values()) {
    sectionIds.add(section.Id);
}
for (AttendanceRecording existing : [SELECT Id, Comments FROM AttendanceRecording WHERE WhatId IN :sectionIds]) {
    if (existing.Comments != null && existing.Comments.startsWith(KEY_PREFIX + '-AR-')) {
        recordingByName.put(existing.Comments, existing);
    }
}
List<AttendanceRecording> recordings = new List<AttendanceRecording>();
for (String code : courseCodes) {
    for (Integer s = 0; s < sessionDaysAgo.size(); s++) {
        String recordingName = KEY_PREFIX + '-AR-' + code + '-' + (s + 1);
        AttendanceRecording recording = recordingByName.containsKey(recordingName)
            ? recordingByName.get(recordingName) : new AttendanceRecording(Comments = recordingName);
        Date meetingDate = TODAY_DATE.addDays(-sessionDaysAgo[s]);
        recording.AttendanceDate = meetingDate;
        recording.AttendanceSubmissionDateTm = Datetime.newInstance(meetingDate, Time.newInstance(12, 0, 0, 0));
        recording.WhatId = sectionByCode.get(code).Id;
        recording.Type = 'Full Day';
        recording.Status = 'Submitted';
        recordingByName.put(recordingName, recording);
        recordings.add(recording);
    }
}
upsert recordings;

// Entries match on student + recording (Name is an auto-number here too).
Map<String, AttendanceEntry> entryByKey = new Map<String, AttendanceEntry>();
for (AttendanceEntry existing : [SELECT Id, WhoId, AttendanceRecordingId FROM AttendanceEntry
        WHERE AttendanceRecordingId IN :recordings]) {
    entryByKey.put(existing.WhoId + '|' + existing.AttendanceRecordingId, existing);
}
List<AttendanceEntry> entries = new List<AttendanceEntry>();
for (Integer i = 0; i < cohort.size(); i++) {
    Integer absencesLeft = (Integer) cohort[i][3];
    for (String code : courseCodes) {
        for (Integer s = 0; s < sessionDaysAgo.size(); s++) {
            AttendanceRecording recording = recordingByName.get(KEY_PREFIX + '-AR-' + code + '-' + (s + 1));
            String entryKey = students[i].Id + '|' + recording.Id;
            AttendanceEntry entry = entryByKey.containsKey(entryKey) ? entryByKey.get(entryKey)
                : new AttendanceEntry(WhoId = students[i].Id, AttendanceRecordingId = recording.Id);
            // Absences take the most recent sessions (sessionDaysAgo is newest first).
            Boolean absent = absencesLeft > 0;
            if (absent) {
                absencesLeft--;
            }
            entry.Status = absent ? 'Absent' : 'Present';
            entry.AttendanceDate = recording.AttendanceDate;
            entry.AttendanceEntrySubmissionDt = recording.AttendanceSubmissionDateTm;
            entries.add(entry);
        }
    }
}
upsert entries;

// ---- Simulated classroom activity (upsert on External Key) ------------------
List<Classroom_Activity__c> activity = new List<Classroom_Activity__c>();
for (Integer i = 0; i < cohort.size(); i++) {
    List<Decimal> grades = (List<Decimal>) cohort[i][5];
    Integer daysSinceLogin = (Integer) cohort[i][4];
    for (Integer c = 0; c < courseCodes.size(); c++) {
        activity.add(new Classroom_Activity__c(
            External_Key__c = KEY_PREFIX + '-' + cohort[i][0] + '|' + courseCodes[c],
            Student__c = students[i].Id,
            Course_Offering__c = sectionByCode.get(courseCodes[c]).Id,
            Course_Name__c = courseNames[c],
            // Same last login across courses: the student stopped logging in everywhere.
            Last_Login__c = NOW_TIME.addDays(-daysSinceLogin).addHours(-1),
            Current_Grade__c = grades[c * 2],
            Grade_Two_Weeks_Ago__c = grades[c * 2 + 1],
            Source_System__c = 'Simulated'
        ));
    }
}
upsert activity External_Key__c;

// ---- Advisee Record + success team (assigned advisor) ------------------------
Map<Id, Case> adviseeByStudent = new Map<Id, Case>();
for (Case existing : [SELECT Id, ContactId FROM Case WHERE RecordTypeId = :adviseeRecordType AND ContactId IN :students]) {
    adviseeByStudent.put(existing.ContactId, existing);
}
List<Case> advisees = new List<Case>();
for (Contact student : students) {
    Case advisee = adviseeByStudent.containsKey(student.Id) ? adviseeByStudent.get(student.Id)
        : new Case(RecordTypeId = adviseeRecordType, ContactId = student.Id, AccountId = student.AccountId, Status = 'Working');
    advisee.Subject = 'Advisee Record - ' + student.FirstName + ' ' + student.LastName;
    advisee.Origin = 'Web';
    advisees.add(advisee);
}
upsert advisees;

Set<Id> haveAdvisor = new Set<Id>();
for (CaseTeamMember member : [SELECT ParentId FROM CaseTeamMember WHERE ParentId IN :advisees
        AND MemberId = :advisor.Id AND TeamRoleId = :advisorRole.Id]) {
    haveAdvisor.add(member.ParentId);
}
List<CaseTeamMember> newMembers = new List<CaseTeamMember>();
for (Case advisee : advisees) {
    if (!haveAdvisor.contains(advisee.Id)) {
        newMembers.add(new CaseTeamMember(ParentId = advisee.Id, MemberId = advisor.Id, TeamRoleId = advisorRole.Id));
    }
}
insert newMembers;

System.debug('SCA-8 demo load complete: ' + students.size() + ' students, ' + entries.size()
    + ' attendance entries, ' + activity.size() + ' classroom activity rows, '
    + newMembers.size() + ' new advisor assignments.');

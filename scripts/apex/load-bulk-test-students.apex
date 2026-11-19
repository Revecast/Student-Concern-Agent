/*****************************************************************
Name:          load-bulk-test-students.apex  (anonymous Apex)
============================================================
Purpose:       Loads 220 synthetic first-year students for the SCA-9
               bulk proof (nightly scorer over 200+ students without
               governor errors), per ADR-014. All under ONE account,
               "DEMO - Bulk Test Students (safe to delete)", with
               emails at a reserved, never-delivering domain.

               Student n (1..220) gets, in the DEMO Fall 2026 term:
                 - an Active, Freshman term enrollment
                 - (n mod 4) Absent entries in the last 14 days
                 - one BIO 101 classroom row: last login (n mod 12)
                   days ago; grade 65 when n mod 10 = 0, else 85
               so scores spread from 0 to 11 and can be checked.

               Idempotent (match on email / student + term / external
               key). Never deletes. Afterwards run
               withdraw-bulk-test-students.apex so nightly runs skip
               them. Run load-demo-data.sh first (it creates the term
               and sections).
============================================================
History
-------
VERSION  AUTHOR                 DATE         DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026   Created   SCA-9 / ADR-014
*****************************************************************/
Integer HOW_MANY = 220;
String ACCOUNT_NAME = 'DEMO - Bulk Test Students (safe to delete)';
String EMAIL_DOMAIN = 'bulk.student.jaxstate.example';
Date TODAY_DATE = Date.today();
List<Integer> sessionDaysAgo = new List<Integer>{2, 4, 9, 11};

AcademicTerm term = [SELECT Id FROM AcademicTerm WHERE Name = 'DEMO Fall 2026' LIMIT 1];
CourseOffering section = [SELECT Id FROM CourseOffering WHERE Name = 'DEMO BIO-101 Fall 2026' LIMIT 1];

// ---- One shared account -----------------------------------------------------
List<Account> accounts = [SELECT Id FROM Account WHERE Name = :ACCOUNT_NAME LIMIT 1];
Account bulkAccount = accounts.isEmpty() ? new Account(Name = ACCOUNT_NAME) : accounts[0];
bulkAccount.Description = 'Synthetic bulk-test students for the SCA-9 scorer proof (ADR-014). Fictional. Safe to delete.';
upsert bulkAccount;

// ---- Students (match on email) ---------------------------------------------
Map<String, Contact> contactByEmail = new Map<String, Contact>();
for (Contact existing : [SELECT Id, Email FROM Contact WHERE AccountId = :bulkAccount.Id]) {
    contactByEmail.put(existing.Email.toLowerCase(), existing);
}
List<Contact> students = new List<Contact>();
for (Integer n = 1; n <= HOW_MANY; n++) {
    String num = String.valueOf(n).leftPad(3, '0');
    String email = 'bulk' + num + '@' + EMAIL_DOMAIN;
    Contact student = contactByEmail.containsKey(email) ? contactByEmail.get(email) : new Contact(Email = email);
    student.FirstName = 'Bulk';
    student.LastName = 'Student ' + num;
    student.AccountId = bulkAccount.Id;
    student.Title = 'Synthetic bulk-test student';
    student.Description = 'Synthetic bulk-test student (SCA-9 / ADR-014). Safe to delete.';
    students.add(student);
}
upsert students;

// ---- Term enrollment: Freshman, Active (match on student + term) -----------
Map<Id, AcademicTermEnrollment> enrollmentByStudent = new Map<Id, AcademicTermEnrollment>();
for (AcademicTermEnrollment existing : [SELECT Id, LearnerContactId FROM AcademicTermEnrollment
        WHERE AcademicTermId = :term.Id AND LearnerContactId IN :students]) {
    enrollmentByStudent.put(existing.LearnerContactId, existing);
}
List<AcademicTermEnrollment> enrollments = new List<AcademicTermEnrollment>();
for (Contact student : students) {
    AcademicTermEnrollment enrollment = enrollmentByStudent.containsKey(student.Id)
        ? enrollmentByStudent.get(student.Id)
        : new AcademicTermEnrollment(LearnerContactId = student.Id, AcademicTermId = term.Id);
    enrollment.EnrollmentStatus = 'Active';
    enrollment.StudyYearClassification = 'Freshman';
    enrollment.EnrollmentReason = 'First Time';
    enrollment.StudentAcademicLevel = 'Undergraduate';
    enrollment.EnrollmentDate = Date.newInstance(2026, 8, 24);
    enrollments.add(enrollment);
}
upsert enrollments;

// ---- Attendance: 4 bulk recordings, entries only for absences --------------
Map<String, AttendanceRecording> recordingByKey = new Map<String, AttendanceRecording>();
// Comments (a long text field) cannot be filtered in SOQL, so filter the section's recordings here.
for (AttendanceRecording existing : [SELECT Id, Comments FROM AttendanceRecording WHERE WhatId = :section.Id]) {
    if (existing.Comments != null && existing.Comments.startsWith('BULK-AR-')) {
        recordingByKey.put(existing.Comments, existing);
    }
}
List<AttendanceRecording> recordings = new List<AttendanceRecording>();
for (Integer s = 0; s < sessionDaysAgo.size(); s++) {
    String key = 'BULK-AR-' + (s + 1);
    AttendanceRecording recording = recordingByKey.containsKey(key) ? recordingByKey.get(key)
        : new AttendanceRecording(Comments = key, WhatId = section.Id);
    Date meetingDate = TODAY_DATE.addDays(-sessionDaysAgo[s]);
    recording.AttendanceDate = meetingDate;
    recording.AttendanceSubmissionDateTm = Datetime.newInstance(meetingDate, Time.newInstance(12, 0, 0, 0));
    recording.Type = 'Full Day';
    recording.Status = 'Submitted';
    recordings.add(recording);
}
upsert recordings;

Map<String, AttendanceEntry> entryByKey = new Map<String, AttendanceEntry>();
for (AttendanceEntry existing : [SELECT Id, WhoId, AttendanceRecordingId FROM AttendanceEntry
        WHERE AttendanceRecordingId IN :recordings]) {
    entryByKey.put(existing.WhoId + '|' + existing.AttendanceRecordingId, existing);
}
List<AttendanceEntry> entries = new List<AttendanceEntry>();
for (Integer i = 0; i < students.size(); i++) {
    Integer absences = Math.mod(i + 1, 4);
    for (Integer s = 0; s < recordings.size(); s++) {
        String key = students[i].Id + '|' + recordings[s].Id;
        AttendanceEntry entry = entryByKey.containsKey(key) ? entryByKey.get(key)
            : new AttendanceEntry(WhoId = students[i].Id, AttendanceRecordingId = recordings[s].Id);
        entry.Status = s < absences ? 'Absent' : 'Present';
        entry.AttendanceDate = recordings[s].AttendanceDate;
        entry.AttendanceEntrySubmissionDt = recordings[s].AttendanceSubmissionDateTm;
        entries.add(entry);
    }
}
upsert entries;

// ---- Simulated classroom activity (upsert on External Key) ------------------
List<Classroom_Activity__c> activity = new List<Classroom_Activity__c>();
for (Integer i = 0; i < students.size(); i++) {
    Integer n = i + 1;
    Decimal grade = Math.mod(n, 10) == 0 ? 65 : 85;
    activity.add(new Classroom_Activity__c(
        External_Key__c = 'BULK-' + String.valueOf(n).leftPad(3, '0') + '|BIO-101',
        Student__c = students[i].Id,
        Course_Offering__c = section.Id,
        Course_Name__c = 'BIO 101 - Introduction to Biology',
        Last_Login__c = Datetime.now().addDays(-Math.mod(n, 12)).addHours(-1),
        Current_Grade__c = grade,
        Grade_Two_Weeks_Ago__c = grade,
        Source_System__c = 'Simulated'));
}
upsert activity External_Key__c;

System.debug('SCA-9 bulk load complete: ' + students.size() + ' students, ' + enrollments.size()
    + ' enrollments, ' + entries.size() + ' attendance entries, ' + activity.size() + ' classroom rows.');

/*****************************************************************
Name:          StudentAbsenceCounterTest
============================================================
Purpose:       Tests for StudentAbsenceCounter (SCA-9 / ADR-012).
               Data assumptions: all data is created here (no
               SeeAllData). One attendance recording per day; entries
               are Absent, Present or Tardy for synthetic students.
               Expected: only Absent entries on or after each request's
               window start are counted, results keep request order,
               and 220 students cost one query.
============================================================
History
-------
VERSION  AUTHOR                  DATE         DETAIL    DESCRIPTION
1.0      Revecast Orchestrate    19/11/2026   Created   SCA-9 / ADR-012
*****************************************************************/
@isTest
private class StudentAbsenceCounterTest {

    private static final Integer BULK_STUDENTS = 220;

    // Creates students under one account; returns them in creation order.
    private static List<Contact> createStudents(Integer howMany) {
        Account household = new Account(Name = 'Test Students');
        insert household;
        List<Contact> students = new List<Contact>();
        for (Integer i = 0; i < howMany; i++) {
            students.add(new Contact(LastName = 'Student ' + i, AccountId = household.Id));
        }
        insert students;
        return students;
    }

    // A recording must relate to someone or something; tests anchor it on one instructor Contact.
    private static Contact instructor;

    // Creates one attendance recording dated daysAgo days before today.
    private static AttendanceRecording createRecording(Integer daysAgo) {
        if (instructor == null) {
            instructor = new Contact(LastName = 'Test Instructor');
            insert instructor;
        }
        Date meetingDate = Date.today().addDays(-daysAgo);
        AttendanceRecording recording = new AttendanceRecording(
            WhoId = instructor.Id,
            Type = 'Full Day',
            AttendanceDate = meetingDate,
            AttendanceSubmissionDateTm = Datetime.newInstance(meetingDate, Time.newInstance(12, 0, 0, 0)));
        insert recording;
        return recording;
    }

    // Builds (does not insert) one entry for a student on a recording.
    private static AttendanceEntry entry(Contact student, AttendanceRecording recording, String status) {
        return new AttendanceEntry(
            WhoId = student.Id,
            AttendanceRecordingId = recording.Id,
            AttendanceDate = recording.AttendanceDate,
            AttendanceEntrySubmissionDt = recording.AttendanceSubmissionDateTm,
            Status = status);
    }

    private static StudentAbsenceCounter.Request request(Id studentId, Date windowStart) {
        StudentAbsenceCounter.Request request = new StudentAbsenceCounter.Request();
        request.studentId = studentId;
        request.windowStart = windowStart;
        return request;
    }

    /*
     * Bulk: 220 students. Student i has (i mod 4) Absent entries inside the window,
     * plus one Present and one Tardy entry that must not count. Expect exact counts,
     * request order preserved and a single SOQL query for the whole batch.
     */
    @isTest
    static void countsAbsencesForBulkBatchWithOneQuery() {
        List<Contact> students = createStudents(BULK_STUDENTS);
        List<AttendanceRecording> recordings = new List<AttendanceRecording>{
            createRecording(1), createRecording(2), createRecording(3), createRecording(4), createRecording(5)
        };
        List<AttendanceEntry> entries = new List<AttendanceEntry>();
        for (Integer i = 0; i < students.size(); i++) {
            Integer absences = Math.mod(i, 4);
            for (Integer a = 0; a < absences; a++) {
                entries.add(entry(students[i], recordings[a], StudentAbsenceCounter.ABSENT_STATUS));
            }
            entries.add(entry(students[i], recordings[3], 'Present'));
            entries.add(entry(students[i], recordings[4], 'Tardy'));
        }
        insert entries;

        List<StudentAbsenceCounter.Request> requests = new List<StudentAbsenceCounter.Request>();
        for (Contact student : students) {
            requests.add(request(student.Id, Date.today().addDays(-14)));
        }

        Test.startTest();
        List<StudentAbsenceCounter.Result> results = StudentAbsenceCounter.countAbsences(requests);
        Integer queriesUsed = Limits.getQueries();
        Test.stopTest();

        System.assertEquals(BULK_STUDENTS, results.size(), 'One result per request');
        for (Integer i = 0; i < results.size(); i++) {
            System.assertEquals(Math.mod(i, 4), results[i].absenceCount, 'Exact Absent count for student ' + i);
        }
        System.assertEquals(1, queriesUsed, 'The whole batch must use exactly one query');
    }

    /*
     * Window: absences before the window start are ignored, and two requests in the
     * same batch with different windows each get their own exact count.
     */
    @isTest
    static void appliesEachRequestsOwnWindow() {
        Contact student = createStudents(1)[0];
        AttendanceRecording recent = createRecording(2);
        AttendanceRecording older = createRecording(10);
        AttendanceRecording outside = createRecording(20);
        insert new List<AttendanceEntry>{
            entry(student, recent, 'Absent'), entry(student, older, 'Absent'), entry(student, outside, 'Absent')
        };

        Test.startTest();
        List<StudentAbsenceCounter.Result> results = StudentAbsenceCounter.countAbsences(
            new List<StudentAbsenceCounter.Request>{
                request(student.Id, Date.today().addDays(-14)),
                request(student.Id, Date.today().addDays(-5))
            });
        Test.stopTest();

        System.assertEquals(2, results[0].absenceCount, '14-day window: the 2- and 10-day absences');
        System.assertEquals(1, results[1].absenceCount, '5-day window: only the 2-day absence');
    }

    /*
     * Negative: a student with no entries, an incomplete request and a null request
     * all return 0 without an error; an empty or null list returns an empty list.
     */
    @isTest
    static void handlesMissingAndIncompleteRequests() {
        Contact student = createStudents(1)[0];

        Test.startTest();
        List<StudentAbsenceCounter.Result> results = StudentAbsenceCounter.countAbsences(
            new List<StudentAbsenceCounter.Request>{
                request(student.Id, Date.today().addDays(-14)),
                request(null, Date.today()),
                request(student.Id, null),
                null
            });
        List<StudentAbsenceCounter.Result> emptyResults = StudentAbsenceCounter.countAbsences(
            new List<StudentAbsenceCounter.Request>());
        List<StudentAbsenceCounter.Result> nullResults = StudentAbsenceCounter.countAbsences(null);
        Test.stopTest();

        System.assertEquals(4, results.size(), 'One result per request, even incomplete ones');
        for (StudentAbsenceCounter.Result result : results) {
            System.assertEquals(0, result.absenceCount, 'No absences or incomplete request gives 0');
        }
        System.assert(emptyResults.isEmpty(), 'Empty input gives empty output');
        System.assert(nullResults.isEmpty(), 'Null input gives empty output');
    }
}

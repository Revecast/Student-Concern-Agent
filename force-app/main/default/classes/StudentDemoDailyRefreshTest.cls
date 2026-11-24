/*****************************************************************
Name:          StudentDemoDailyRefreshTest
============================================================
Purpose:       Tests for StudentDemoDailyRefresh (SCA-45).
               Data assumptions: all data is created here (no SeeAllData).
               Five demo students (Jordan, Casey, Quinn, Taylor, Avery) with
               twelve demo attendance meetings each and three classroom
               activity rows, plus one UAT student that must be ignored.
               Expected: dates move relative to the given day, featured
               students get their crossing story and yesterday's score with
               the alert date cleared, others keep their normal story, and
               only earlier alerts/Tasks are closed.
============================================================
History
-------
VERSION  AUTHOR                 DATE         DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   24/11/2026   Created   SCA-45
*****************************************************************/
@isTest
private class StudentDemoDailyRefreshTest {

    // 2026-11-24 is rotation day 0: Jordan + Casey are featured.
    private static final Date DAY_ZERO = Date.newInstance(2026, 11, 24);
    private static final List<String> KEYS = new List<String>{
        'jordan.rivera', 'casey.nguyen', 'quinn.okafor', 'taylor.brooks', 'avery.chen'};

    @testSetup
    static void createDemoData() {
        Account household = new Account(Name = 'Test Demo Students');
        insert as system household;
        List<Contact> students = new List<Contact>();
        for (String key : KEYS) {
            students.add(new Contact(FirstName = key.substringBefore('.'), LastName = key.substringAfter('.'),
                Email = key + StudentDemoDailyRefresh.EMAIL_DOMAIN, AccountId = household.Id,
                Risk_Score__c = 7, Risk_Last_Alerted_Date__c = DAY_ZERO.addDays(-2)));
        }
        // Same name pattern on the UAT domain: must not be touched.
        students.add(new Contact(FirstName = 'Jordan', LastName = 'Uat', AccountId = household.Id,
            Email = 'jordan.rivera@uat.student.jaxstate.example', Risk_Score__c = 7));
        insert as system students;

        Contact instructor = new Contact(LastName = 'Test Instructor', AccountId = household.Id);
        insert as system instructor;
        List<AttendanceRecording> recordings = new List<AttendanceRecording>();
        for (String code : StudentDemoDailyRefresh.COURSE_CODES) {
            for (Integer s = 1; s <= 4; s++) {
                recordings.add(new AttendanceRecording(WhoId = instructor.Id, Type = 'Full Day',
                    Comments = StudentDemoDailyRefresh.RECORDING_PREFIX + code + '-' + s,
                    AttendanceDate = Date.newInstance(2026, 10, 1),
                    AttendanceSubmissionDateTm = Datetime.newInstance(2026, 10, 1, 12, 0, 0)));
            }
        }
        insert as system recordings;

        List<AttendanceEntry> entries = new List<AttendanceEntry>();
        List<Classroom_Activity__c> activity = new List<Classroom_Activity__c>();
        for (Contact student : students) {
            for (AttendanceRecording recording : recordings) {
                entries.add(new AttendanceEntry(WhoId = student.Id, AttendanceRecordingId = recording.Id,
                    Status = 'Present', AttendanceDate = recording.AttendanceDate,
                    AttendanceEntrySubmissionDt = recording.AttendanceSubmissionDateTm));
            }
            for (String code : StudentDemoDailyRefresh.COURSE_CODES) {
                activity.add(new Classroom_Activity__c(Student__c = student.Id,
                    External_Key__c = student.Email + '|' + code, Course_Name__c = code,
                    Last_Login__c = Datetime.newInstance(2026, 10, 1, 12, 0, 0)));
            }
        }
        insert as system entries;
        insert as system activity;
    }

    private static Map<String, Contact> studentsByKey() {
        Map<String, Contact> byKey = new Map<String, Contact>();
        for (Contact student : [SELECT Id, Email, Risk_Score__c, Risk_Reason__c, Risk_Last_Alerted_Date__c
                FROM Contact WHERE Email != null]) {
            byKey.put(student.Email.substringBefore('@') + (student.Email.contains('@uat.') ? '@uat' : ''), student);
        }
        return byKey;
    }

    private static Integer absences(Id studentId) {
        return [SELECT COUNT() FROM AttendanceEntry WHERE WhoId = :studentId AND Status = 'Absent'];
    }

    private static Integer daysSinceLogin(Id studentId, Date today) {
        Classroom_Activity__c row = [SELECT Last_Login__c FROM Classroom_Activity__c
            WHERE Student__c = :studentId LIMIT 1];
        return row.Last_Login__c.date().daysBetween(today);
    }

    /*
     * Day zero: Jordan and Casey are featured. Expect crossing stories, yesterday's
     * scores, cleared alert dates; Quinn/Taylor/Avery keep normal stories and scores;
     * the UAT student is untouched; meeting dates follow the day.
     */
    @isTest
    static void featuresJordanAndTodaysRotationStudent() {
        Test.startTest();
        Integer refreshed = StudentDemoDailyRefresh.refresh(DAY_ZERO);
        Test.stopTest();

        System.assertEquals(5, refreshed, 'Only the five demo-domain students are refreshed');
        Map<String, Contact> byKey = studentsByKey();
        Contact jordan = byKey.get('jordan.rivera');
        System.assertEquals(4, jordan.Risk_Score__c, 'Jordan is set back to yesterday\'s score');
        System.assertEquals(null, jordan.Risk_Last_Alerted_Date__c, 'Cooldown cleared so he can alert');
        System.assertEquals(2, absences(jordan.Id), 'Jordan misses 2 classes');
        System.assertEquals(5, daysSinceLogin(jordan.Id, DAY_ZERO), 'Jordan last logged in 5 days ago');

        Contact casey = byKey.get('casey.nguyen');
        System.assertEquals(3, casey.Risk_Score__c, 'Casey is set back to yesterday\'s score');
        System.assertEquals(2, absences(casey.Id), 'Casey gets her crossing absences');

        Contact quinn = byKey.get('quinn.okafor');
        System.assertEquals(7, quinn.Risk_Score__c, 'A student not featured keeps the score');
        System.assertNotEquals(null, quinn.Risk_Last_Alerted_Date__c, 'and keeps the cooldown');
        System.assertEquals(1, absences(quinn.Id), 'Quinn keeps the normal story');

        Contact avery = byKey.get('avery.chen');
        System.assertEquals(0, absences(avery.Id), 'Avery keeps the normal story');
        System.assertEquals(11, daysSinceLogin(avery.Id, DAY_ZERO), 'Avery last logged in 11 days ago');

        Contact uat = byKey.get('jordan.rivera@uat');
        System.assertEquals(7, uat.Risk_Score__c, 'The UAT student is not touched');
        System.assertEquals(0, absences(uat.Id), 'The UAT student attendance is not touched');

        AttendanceRecording newest = [SELECT AttendanceDate FROM AttendanceRecording
            WHERE AttendanceDate != :Date.newInstance(2026, 10, 1) ORDER BY AttendanceDate DESC LIMIT 1];
        System.assertEquals(DAY_ZERO.addDays(-2), newest.AttendanceDate, 'Newest meeting is 2 days back');
    }

    /*
     * The rotation moves daily: day 1 Quinn, day 2 Taylor, day 3 Casey again; Jordan always.
     * On day 1, Casey goes back to her normal story (no absences).
     */
    @isTest
    static void rotatesTheSecondStudentEachDay() {
        System.assertEquals(new Set<String>{'jordan.rivera', 'quinn.okafor'},
            StudentDemoDailyRefresh.featuredOn(DAY_ZERO.addDays(1)), 'Day 1');
        System.assertEquals(new Set<String>{'jordan.rivera', 'taylor.brooks'},
            StudentDemoDailyRefresh.featuredOn(DAY_ZERO.addDays(2)), 'Day 2');
        System.assertEquals(new Set<String>{'jordan.rivera', 'casey.nguyen'},
            StudentDemoDailyRefresh.featuredOn(DAY_ZERO.addDays(3)), 'Day 3');

        Test.startTest();
        StudentDemoDailyRefresh.refresh(DAY_ZERO);
        StudentDemoDailyRefresh.refresh(DAY_ZERO.addDays(1));
        Test.stopTest();

        Map<String, Contact> byKey = studentsByKey();
        System.assertEquals(0, absences(byKey.get('casey.nguyen').Id), 'Casey back to normal');
        System.assertEquals(3, absences(byKey.get('quinn.okafor').Id), 'Quinn crossing story');
        System.assertEquals(4, byKey.get('quinn.okafor').Risk_Score__c, 'Quinn yesterday score');
    }

    /*
     * Earlier alerts and Tasks are closed; today's stay open; other Tasks are left alone.
     */
    @isTest
    static void closesOnlyEarlierAlertsAndTasks() {
        Contact jordan = studentsByKey().get('jordan.rivera');
        RecordAlert oldAlert = new RecordAlert(WhatId = jordan.Id, Subject = 'Old', IsActive = true,
            Severity = 'Warning', EffectiveDate = System.now().addDays(-3), ValidUntilDate = System.now().addDays(4));
        RecordAlert newAlert = new RecordAlert(WhatId = jordan.Id, Subject = 'New', IsActive = true,
            Severity = 'Warning', EffectiveDate = System.now(), ValidUntilDate = System.now().addDays(7));
        insert as system new List<RecordAlert>{oldAlert, newAlert};
        Task oldTask = new Task(WhoId = jordan.Id, Subject = 'Check in with Jordan Rivera', Status = 'Not Started');
        Task newTask = new Task(WhoId = jordan.Id, Subject = 'Check in with Jordan Rivera', Status = 'Not Started');
        Task otherTask = new Task(WhoId = jordan.Id, Subject = 'Call about housing', Status = 'Not Started');
        insert as system new List<Task>{oldTask, newTask, otherTask};
        Datetime threeDaysAgo = System.now().addDays(-3);
        Test.setCreatedDate(oldAlert.Id, threeDaysAgo);
        Test.setCreatedDate(oldTask.Id, threeDaysAgo);
        Test.setCreatedDate(otherTask.Id, threeDaysAgo);

        Test.startTest();
        StudentDemoDailyRefresh.refresh(Date.today());
        Test.stopTest();

        System.assertEquals(false, [SELECT IsActive FROM RecordAlert WHERE Id = :oldAlert.Id].IsActive, 'Old alert off');
        System.assertEquals(true, [SELECT IsActive FROM RecordAlert WHERE Id = :newAlert.Id].IsActive, 'Today\'s alert on');
        System.assertEquals(true, [SELECT IsClosed FROM Task WHERE Id = :oldTask.Id].IsClosed, 'Old check-in Task done');
        System.assertEquals(false, [SELECT IsClosed FROM Task WHERE Id = :newTask.Id].IsClosed, 'Today\'s Task open');
        System.assertEquals(false, [SELECT IsClosed FROM Task WHERE Id = :otherTask.Id].IsClosed, 'Other Task untouched');
    }

    /*
     * Scheduling registers one nightly job at 01:30; the scheduled run refreshes the demo.
     */
    @isTest
    static void schedulesAndRunsNightly() {
        Test.startTest();
        Id jobId = StudentDemoDailyRefresh.scheduleNightly();
        Test.stopTest();
        CronTrigger job = [SELECT CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(StudentDemoDailyRefresh.NIGHTLY_CRON, job.CronExpression, 'Runs at 01:30 daily');
        // Test.stopTest runs the scheduled job once: Jordan is always featured.
        System.assertEquals(null, studentsByKey().get('jordan.rivera').Risk_Last_Alerted_Date__c,
            'The scheduled run refreshed the demo');
    }

    /*
     * No demo students: nothing changes and nothing fails.
     */
    @isTest
    static void doesNothingWithoutDemoStudents() {
        delete as system [SELECT Id FROM Classroom_Activity__c];
        delete as system [SELECT Id FROM AttendanceEntry];
        delete as system [SELECT Id FROM Contact WHERE Email LIKE '%@student.jaxstate.example'];
        Test.startTest();
        Integer refreshed = StudentDemoDailyRefresh.refresh(DAY_ZERO);
        Test.stopTest();
        System.assertEquals(0, refreshed, 'Nothing to refresh');
    }
}

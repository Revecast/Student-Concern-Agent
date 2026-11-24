/*****************************************************************
Name:          StudentDemoDailyRefresh
============================================================
Purpose:       Keeps the Student Concern demo ready every day with no
               manual reset (SCA-45). Scheduled nightly at 01:30 Pacific,
               half an hour before the real scorer (SCH – Score First Year
               Students, 02:00). Each run:
                 1. Moves the demo cohort's attendance and last-login dates
                    forward so every student keeps the same story relative
                    to today (the data never ages into surprise alerts).
                 2. Picks today's featured students: Jordan Rivera every day,
                    plus one of Casey Nguyen, Quinn Okafor and Taylor Brooks
                    in turn. Their data gets the "crossing" version of their
                    story, and their score is set back to yesterday's value
                    (below the alert limit) with Risk Last Alerted Date
                    cleared, so the 02:00 scorer takes them over the limit
                    and the normal flows alert the assigned advisor.
                 3. Tidies earlier days: deactivates older Record Alerts and
                    completes older open "Check in with" Tasks on the demo
                    students. Nothing is deleted.
               Demo only: it touches nothing but the 21 fictional demo
               students (email domain student.jaxstate.example). It never
               writes the score that triggers an alert; the real scorer and
               flows do that. It only lowers a featured student's score,
               which the crossing flow ignores (it starts on increases only).
               Writes run as system (DML as system): the scheduling user
               may only have read access to the risk and activity fields.
               To stop it: Setup > Scheduled Jobs > delete
               "Student Demo Daily Refresh".
               Featured students all have the presenter as their only
               assigned advisor (Avery, Morgan and Riley also have UAT
               advisors, so their alerts could go to someone else).
============================================================
History
-------
VERSION  AUTHOR                 DATE         DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   24/11/2026   Created   SCA-45: no night-before reset
*****************************************************************/
public without sharing class StudentDemoDailyRefresh implements Schedulable {

    public static final String JOB_NAME = 'Student Demo Daily Refresh';
    // 01:30 every day in the scheduling user's time zone (Pacific in this org).
    public static final String NIGHTLY_CRON = '0 30 1 * * ?';
    public static final String EMAIL_DOMAIN = '@student.jaxstate.example';
    public static final String RECORDING_PREFIX = 'DEMO-AR-';
    public static final String TASK_SUBJECT_PREFIX = 'Check in with ';
    // Courses in the order absences are filled (newest sessions of BIO 101 first).
    public static final List<String> COURSE_CODES = new List<String>{'BIO-101', 'ENG-101', 'MATH-110'};
    // Days ago of each course's four meetings, session 1 = newest (same as load-demo-data.apex).
    public static final List<Integer> SESSION_DAYS_AGO = new List<Integer>{2, 4, 9, 11};
    // Students featured in turn next to Jordan. Day 0 of the turn is 2026-11-24.
    public static final List<String> ROTATION = new List<String>{'casey.nguyen', 'quinn.okafor', 'taylor.brooks'};
    public static final Date ROTATION_START = Date.newInstance(2026, 11, 24);
    public static final String ALWAYS_FEATURED = 'jordan.rivera';

    // Story for each demo student: absences in the last 14 days and days since
    // last classroom login. Mirrors the cohort table in load-demo-data.apex.
    // Scores with the default weights: Avery 5, Riley 4, Quinn 4, Morgan 3,
    // Casey 3 (grade below C), Taylor 2, everyone else 0. Nobody reaches 6.
    private static final Map<String, List<Integer>> NORMAL_STORY = new Map<String, List<Integer>>{
        'jordan.rivera' => new List<Integer>{2, 3}, 'avery.chen' => new List<Integer>{0, 11},
        'riley.patel' => new List<Integer>{2, 1}, 'quinn.okafor' => new List<Integer>{1, 2},
        'taylor.brooks' => new List<Integer>{1, 2}, 'morgan.silva' => new List<Integer>{0, 6},
        'casey.nguyen' => new List<Integer>{0, 1}, 'alex.romero' => new List<Integer>{0, 1},
        'sam.kowalski' => new List<Integer>{0, 2}, 'jamie.haddad' => new List<Integer>{0, 1},
        'drew.mensah' => new List<Integer>{0, 3}, 'pat.lindqvist' => new List<Integer>{0, 1},
        'reese.tanaka' => new List<Integer>{0, 2}, 'skyler.adeyemi' => new List<Integer>{0, 1},
        'rowan.garcia' => new List<Integer>{0, 1}, 'emery.walsh' => new List<Integer>{0, 2},
        'hayden.kim' => new List<Integer>{0, 1}, 'logan.petrov' => new List<Integer>{0, 3},
        'parker.diallo' => new List<Integer>{0, 1}, 'blake.moreau' => new List<Integer>{0, 2},
        'cameron.iyer' => new List<Integer>{0, 1}
    };
    // Story on the day the student is featured (crosses the limit of 6 at 02:00).
    // Jordan 7: 2 absences + no login 5 days. Casey 7: 2 absences + grade below C.
    // Quinn 8: 3 absences + grade dropped a letter. Taylor 7: 2 absences + no login 6 days.
    private static final Map<String, List<Integer>> CROSSING_STORY = new Map<String, List<Integer>>{
        'jordan.rivera' => new List<Integer>{2, 5}, 'casey.nguyen' => new List<Integer>{2, 1},
        'quinn.okafor' => new List<Integer>{3, 2}, 'taylor.brooks' => new List<Integer>{2, 6}
    };
    // Yesterday's score and reason for a featured student (below the limit).
    private static final Map<String, Integer> YESTERDAY_SCORE = new Map<String, Integer>{
        'jordan.rivera' => 4, 'casey.nguyen' => 3, 'quinn.okafor' => 4, 'taylor.brooks' => 2
    };
    private static final Map<String, String> YESTERDAY_REASON = new Map<String, String>{
        'jordan.rivera' => 'Missed 2 classes in the last 14 days',
        'casey.nguyen' => 'Grade below C in BIO 101',
        'quinn.okafor' => 'Missed 1 class in the last 14 days; grade dropped a letter in BIO 101',
        'taylor.brooks' => 'Missed 1 class in the last 14 days'
    };

    /*****************************************************************
    Purpose:   Schedulable entry point; refreshes the demo for today.
    *****************************************************************/
    public void execute(SchedulableContext context) {
        System.debug('StudentDemoDailyRefresh: start');
        refresh(Date.today());
        System.debug('StudentDemoDailyRefresh: end');
    }

    /*****************************************************************
    Purpose:   Schedules the nightly run (01:30). Returns the CronTrigger Id.
    *****************************************************************/
    public static Id scheduleNightly() {
        return System.schedule(JOB_NAME, NIGHTLY_CRON, new StudentDemoDailyRefresh());
    }

    /*****************************************************************
    Purpose:   Email local parts (first.last) of the students featured on a day.
    Parameters: day - the day the 02:00 scorer will run.
    *****************************************************************/
    public static Set<String> featuredOn(Date day) {
        Integer index = Math.mod(Math.abs(ROTATION_START.daysBetween(day)), ROTATION.size());
        return new Set<String>{ALWAYS_FEATURED, ROTATION[index]};
    }

    /*****************************************************************
    Purpose:   Does the whole refresh for one day (see class header).
    Parameters: today - the day the 02:00 scorer will run.
    Returns:   Number of demo students refreshed.
    *****************************************************************/
    public static Integer refresh(Date today) {
        System.debug('refresh: ' + today);
        Map<Id, String> keyByStudent = new Map<Id, String>();
        List<Contact> students = [SELECT Id, Email FROM Contact WHERE Email LIKE :('%' + EMAIL_DOMAIN) LIMIT 200];
        for (Contact student : students) {
            String key = student.Email.toLowerCase().removeEnd(EMAIL_DOMAIN);
            // Exact domain only (UAT students use uat.student.jaxstate.example).
            if (NORMAL_STORY.containsKey(key) && student.Email.toLowerCase().endsWith(EMAIL_DOMAIN)) {
                keyByStudent.put(student.Id, key);
            }
        }
        if (keyByStudent.isEmpty()) {
            System.debug('refresh: no demo students found, nothing changed');
            return 0;
        }
        Set<String> featured = featuredOn(today);
        moveAttendance(keyByStudent, featured, today);
        moveLogins(keyByStudent, featured, today);
        tidyEarlierDays(keyByStudent.keySet(), today);
        rewindFeatured(keyByStudent, featured);
        System.debug('refresh: ' + keyByStudent.size() + ' students, featured ' + featured);
        return keyByStudent.size();
    }

    // The story (absences, days since login) a student has today.
    private static List<Integer> storyFor(String key, Set<String> featured) {
        if (featured.contains(key) && CROSSING_STORY.containsKey(key)) {
            return CROSSING_STORY.get(key);
        }
        return NORMAL_STORY.get(key);
    }

    // Re-dates the demo attendance recordings and sets each entry Absent or Present.
    private static void moveAttendance(Map<Id, String> keyByStudent, Set<String> featured, Date today) {
        List<AttendanceEntry> entries = [SELECT Id, WhoId, AttendanceRecordingId FROM AttendanceEntry
            WHERE WhoId IN :keyByStudent.keySet() LIMIT 5000];
        Set<Id> recordingIds = new Set<Id>();
        for (AttendanceEntry entry : entries) {
            recordingIds.add(entry.AttendanceRecordingId);
        }
        // Comments holds the session key, e.g. DEMO-AR-BIO-101-1 (Name is an auto-number).
        Map<Id, AttendanceRecording> recordings = new Map<Id, AttendanceRecording>();
        Map<Id, Integer> absenceOrder = new Map<Id, Integer>();
        for (AttendanceRecording recording : [SELECT Id, Comments FROM AttendanceRecording
                WHERE Id IN :recordingIds LIMIT 200]) {
            if (recording.Comments == null || !recording.Comments.startsWith(RECORDING_PREFIX)) {
                continue;
            }
            String sessionKey = recording.Comments.removeStart(RECORDING_PREFIX);
            Integer courseIndex = COURSE_CODES.indexOf(sessionKey.substringBeforeLast('-'));
            Integer session = Integer.valueOf(sessionKey.substringAfterLast('-'));
            if (courseIndex < 0 || session < 1 || session > SESSION_DAYS_AGO.size()) {
                continue;
            }
            Date meetingDate = today.addDays(-SESSION_DAYS_AGO[session - 1]);
            recording.AttendanceDate = meetingDate;
            recording.AttendanceSubmissionDateTm = Datetime.newInstance(meetingDate, Time.newInstance(12, 0, 0, 0));
            recordings.put(recording.Id, recording);
            // Rank 0 = first session to be marked absent (newest BIO 101 meeting).
            absenceOrder.put(recording.Id, courseIndex * SESSION_DAYS_AGO.size() + session - 1);
        }
        update as system recordings.values();

        List<AttendanceEntry> changed = new List<AttendanceEntry>();
        for (AttendanceEntry entry : entries) {
            AttendanceRecording recording = recordings.get(entry.AttendanceRecordingId);
            if (recording == null) {
                continue;
            }
            Integer absences = storyFor(keyByStudent.get(entry.WhoId), featured)[0];
            entry.Status = absenceOrder.get(recording.Id) < absences ? 'Absent' : 'Present';
            entry.AttendanceDate = recording.AttendanceDate;
            entry.AttendanceEntrySubmissionDt = recording.AttendanceSubmissionDateTm;
            changed.add(entry);
        }
        update as system changed;
    }

    // Sets each student's last classroom login (midday, same for every course).
    private static void moveLogins(Map<Id, String> keyByStudent, Set<String> featured, Date today) {
        List<Classroom_Activity__c> activity = [SELECT Id, Student__c FROM Classroom_Activity__c
            WHERE Student__c IN :keyByStudent.keySet() LIMIT 1000];
        for (Classroom_Activity__c row : activity) {
            Integer daysSinceLogin = storyFor(keyByStudent.get(row.Student__c), featured)[1];
            row.Last_Login__c = Datetime.newInstance(today.addDays(-daysSinceLogin), Time.newInstance(12, 0, 0, 0));
        }
        update as system activity;
    }

    // Deactivates earlier alerts and completes earlier open check-in Tasks. Deletes nothing.
    private static void tidyEarlierDays(Set<Id> studentIds, Date today) {
        Datetime startOfToday = Datetime.newInstance(today, Time.newInstance(0, 0, 0, 0));
        List<RecordAlert> alerts = [SELECT Id FROM RecordAlert WHERE WhatId IN :studentIds
            AND IsActive = true AND CreatedDate < :startOfToday LIMIT 1000];
        for (RecordAlert alert : alerts) {
            alert.IsActive = false;
        }
        update as system alerts;
        String subjectPattern = TASK_SUBJECT_PREFIX + '%';
        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId IN :studentIds AND IsClosed = false
            AND Subject LIKE :subjectPattern AND CreatedDate < :startOfToday LIMIT 1000];
        for (Task openTask : tasks) {
            openTask.Status = 'Completed';
        }
        update as system tasks;
        System.debug('tidyEarlierDays: ' + alerts.size() + ' alerts, ' + tasks.size() + ' tasks');
    }

    // Puts featured students back to yesterday's score so the scorer's run is a fresh crossing.
    private static void rewindFeatured(Map<Id, String> keyByStudent, Set<String> featured) {
        List<Contact> rewound = new List<Contact>();
        for (Id studentId : keyByStudent.keySet()) {
            String key = keyByStudent.get(studentId);
            if (featured.contains(key) && YESTERDAY_SCORE.containsKey(key)) {
                rewound.add(new Contact(Id = studentId, Risk_Score__c = YESTERDAY_SCORE.get(key),
                    Risk_Reason__c = YESTERDAY_REASON.get(key), Risk_Last_Alerted_Date__c = null));
            }
        }
        update as system rewound;
    }
}

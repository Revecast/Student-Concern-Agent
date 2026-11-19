/*****************************************************************
Name:          StudentRiskCrossingTest
============================================================
Purpose:       Proves RT – Contact – Risk Crossing (SCA-13) starts outreach
               once on an upward crossing of the alert limit and never
               repeats it inside the cooldown. Limits come from the real
               Risk Score Setting (Default): alert at 6, cooldown 7 days.
               Outreach is visible here as Risk Last Alerted Date being
               stamped; later stories (SCA-14, SCA-15) add the alert and
               check-in and are tested in their own classes.
============================================================
History
-------
VERSION  AUTHOR                 DATE        DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026  Created   SCA-13
*****************************************************************/
@isTest
private class StudentRiskCrossingTest {

    private static final Integer BULK_SIZE = 200;

    /*
     * Builds one account and the requested number of student contacts with
     * a starting score and last alerted date. Assumption: no other automation
     * changes Risk_Score__c on insert.
     */
    private static List<Contact> makeStudents(Integer count, Decimal score, Date lastAlerted) {
        Account adminAccount = new Account(Name = 'Crossing Test Administrative Account');
        insert adminAccount;
        List<Contact> students = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            students.add(new Contact(
                FirstName = 'Student',
                LastName = 'Crossing ' + i,
                AccountId = adminAccount.Id,
                Email = 'crossing' + i + '@student.jaxstate.example',
                Risk_Score__c = score,
                Risk_Last_Alerted_Date__c = lastAlerted
            ));
        }
        insert students;
        return students;
    }

    /* Sets every student's score and saves them in one update. */
    private static void rescore(List<Contact> students, Decimal score) {
        for (Contact student : students) {
            student.Risk_Score__c = score;
        }
        Test.startTest();
        update students;
        Test.stopTest();
    }

    /* Reads the last alerted dates back from the database. */
    private static Map<Id, Contact> reload(List<Contact> students) {
        return new Map<Id, Contact>([
            SELECT Id, Risk_Last_Alerted_Date__c FROM Contact WHERE Id IN :students
        ]);
    }

    /* AC1: a score rising from below 6 to 6 or more starts outreach and stamps today. */
    @isTest
    static void upwardCrossingStampsLastAlertedDate() {
        List<Contact> students = makeStudents(1, 3, null);
        rescore(students, 7);
        System.assertEquals(Date.today(), reload(students).get(students[0].Id).Risk_Last_Alerted_Date__c,
            'An upward crossing should stamp the last alerted date');
    }

    /* AC1 edge: exactly at the limit counts as crossing. */
    @isTest
    static void reachingExactlyTheLimitCounts() {
        List<Contact> students = makeStudents(1, 5, null);
        rescore(students, 6);
        System.assertEquals(Date.today(), reload(students).get(students[0].Id).Risk_Last_Alerted_Date__c,
            'Reaching the limit exactly should count as a crossing');
    }

    /* AC2: alerted 3 days ago, crosses again: no new outreach (date unchanged). */
    @isTest
    static void crossingInsideCooldownStartsNothing() {
        Date threeDaysAgo = Date.today().addDays(-3);
        List<Contact> students = makeStudents(1, 2, threeDaysAgo);
        rescore(students, 8);
        System.assertEquals(threeDaysAgo, reload(students).get(students[0].Id).Risk_Last_Alerted_Date__c,
            'A crossing inside the 7-day cooldown should not start new outreach');
    }

    /* AC2 boundary: exactly 7 days later the cooldown has passed. */
    @isTest
    static void crossingAfterCooldownStartsOutreach() {
        List<Contact> students = makeStudents(1, 2, Date.today().addDays(-7));
        rescore(students, 6);
        System.assertEquals(Date.today(), reload(students).get(students[0].Id).Risk_Last_Alerted_Date__c,
            'After 7 days a new crossing should start outreach again');
    }

    /* AC3: a score that stays above 6 never repeats outreach. */
    @isTest
    static void scoreStayingAboveLimitStartsNothing() {
        Date longAgo = Date.today().addDays(-30);
        List<Contact> students = makeStudents(1, 7, longAgo);
        rescore(students, 9);
        System.assertEquals(longAgo, reload(students).get(students[0].Id).Risk_Last_Alerted_Date__c,
            'A score already above the limit should not start outreach again');
    }

    /* A drop below the limit starts nothing either. */
    @isTest
    static void scoreGoingDownStartsNothing() {
        List<Contact> students = makeStudents(1, 8, null);
        rescore(students, 2);
        System.assertEquals(null, reload(students).get(students[0].Id).Risk_Last_Alerted_Date__c,
            'A falling score should not start outreach');
    }

    /* A first score with no prior value is treated as rising from 0. */
    @isTest
    static void firstScoreAboveLimitCounts() {
        List<Contact> students = makeStudents(1, null, null);
        rescore(students, 7);
        System.assertEquals(Date.today(), reload(students).get(students[0].Id).Risk_Last_Alerted_Date__c,
            'A first score at or above the limit should count as a crossing');
    }

    /* Bulk: 200 students crossing in one nightly batch, no governor errors. */
    @isTest
    static void bulkCrossingStampsEveryStudent() {
        List<Contact> students = makeStudents(BULK_SIZE, 0, null);
        rescore(students, 7);
        Integer stamped = 0;
        for (Contact student : reload(students).values()) {
            if (student.Risk_Last_Alerted_Date__c == Date.today()) {
                stamped++;
            }
        }
        System.assertEquals(BULK_SIZE, stamped, 'Every crossing student in the batch should be stamped');
    }
}

/*****************************************************************
Name:          StudentOutreachValidationTest
============================================================
Purpose:       Proves the NEVER rule (ADR-001) is enforced on the outreach
               log, Student_Outreach__c (SCA-3). Only four recipient types
               are allowed, and each must carry the matching exception:
               Student / Assigned Advisor -> None,
               Counseling Center -> Crisis,
               Advising Queue -> Advising Queue.
               A failed or skipped send must record a reason.
               Uses only records created in the test (no real data).
============================================================
History
-------
VERSION  AUTHOR                 DATE         DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026   Created   SCA-3
*****************************************************************/
@isTest
private class StudentOutreachValidationTest {

    // Number of records used to prove bulk behaviour (standard minimum is 20).
    private static final Integer BULK_SIZE = 40;

    /*****************************************************************
    Purpose:  Creates one fictional student Contact for every test.
    *****************************************************************/
    @testSetup
    static void createStudent() {
        Account school = new Account(Name = 'Test University');
        insert school;

        insert new Contact(
            FirstName = 'Test',
            LastName = 'Student',
            AccountId = school.Id,
            Email = 'test.student@example.edu'
        );
    }

    /*****************************************************************
    Purpose:  Returns the test student's Id.
    Returns:  Id of the Contact created in createStudent.
    *****************************************************************/
    private static Id studentId() {
        return [SELECT Id FROM Contact WHERE LastName = 'Student' LIMIT 1].Id;
    }

    /*****************************************************************
    Purpose:  Builds an unsaved outreach row for the given recipient and
              exception, so each test only states what differs.
    Parameters: recipientType - Recipient_Type__c value
                exceptionUsed - Exception_Used__c value
    Returns:  An unsaved Student_Outreach__c.
    *****************************************************************/
    private static Student_Outreach__c outreach(String recipientType, String exceptionUsed) {
        return new Student_Outreach__c(
            Student__c = studentId(),
            Channel__c = 'Email',
            Recipient_Type__c = recipientType,
            Exception_Used__c = exceptionUsed,
            Status__c = 'Sent',
            Sent_At__c = System.now()
        );
    }

    /*****************************************************************
    Purpose:  Asserts that inserting the record fails and that the error
              message contains the expected text.
    Parameters: row - the record to insert
                expectedText - text the error must contain
    *****************************************************************/
    private static void assertRejected(Student_Outreach__c row, String expectedText) {
        Database.SaveResult result = Database.insert(row, false);
        System.assert(!result.isSuccess(), 'Expected the insert to be rejected');
        String messages = '';
        for (Database.Error err : result.getErrors()) {
            messages += err.getMessage() + ' ';
        }
        System.assert(messages.contains(expectedText),
            'Unexpected error message: ' + messages);
    }

    // Happy path, in bulk: every allowed recipient/exception pair saves.
    @isTest
    static void allowedPairsSaveInBulk() {
        List<Student_Outreach__c> rows = new List<Student_Outreach__c>();
        for (Integer i = 0; i < BULK_SIZE; i++) {
            // Rotate through the four allowed pairs.
            Integer pair = Math.mod(i, 4);
            if (pair == 0) {
                rows.add(outreach('Student', 'None'));
            } else if (pair == 1) {
                rows.add(outreach('Assigned Advisor', 'None'));
            } else if (pair == 2) {
                rows.add(outreach('Counseling Center', 'Crisis'));
            } else {
                rows.add(outreach('Advising Queue', 'Advising Queue'));
            }
        }

        Test.startTest();
        insert rows;
        Test.stopTest();

        System.assertEquals(BULK_SIZE, [SELECT COUNT() FROM Student_Outreach__c],
            'All allowed outreach rows should be saved');
    }

    // A recipient outside the four allowed types (e.g. a professor) is rejected
    // by the restricted picklist.
    @isTest
    static void unknownRecipientTypeRejected() {
        Student_Outreach__c row = outreach('Professor', 'None');
        Database.SaveResult result = Database.insert(row, false);
        System.assert(!result.isSuccess(), 'A recipient type outside the NEVER rule must be rejected');
        System.assertEquals(0, [SELECT COUNT() FROM Student_Outreach__c], 'Nothing should be saved');
    }

    // Every outreach must say who received it.
    @isTest
    static void missingRecipientTypeRejected() {
        assertRejected(outreach(null, 'None'), 'Choose who received this outreach');
    }

    // The counseling center may only be contacted as the Crisis exception.
    @isTest
    static void counselingWithoutCrisisRejected() {
        assertRejected(outreach('Counseling Center', 'None'), 'Exception Used does not match Recipient Type');
    }

    // The advising queue may only be used as the Advising Queue exception.
    @isTest
    static void queueWithoutExceptionRejected() {
        assertRejected(outreach('Advising Queue', 'None'), 'Exception Used does not match Recipient Type');
    }

    // The student and assigned advisor never need an exception, so claiming one is wrong.
    @isTest
    static void studentWithExceptionRejected() {
        assertRejected(outreach('Student', 'Crisis'), 'Exception Used does not match Recipient Type');
        assertRejected(outreach('Assigned Advisor', 'Advising Queue'), 'Exception Used does not match Recipient Type');
    }

    // A failed send is logged, but only with a reason (SCA-37).
    @isTest
    static void failedSendNeedsReason() {
        Student_Outreach__c failed = outreach('Student', 'None');
        failed.Status__c = 'Failed';
        assertRejected(failed, 'Add a failure reason');

        failed.Failure_Reason__c = 'No school email on file';
        insert failed;
        System.assertEquals(1, [SELECT COUNT() FROM Student_Outreach__c WHERE Status__c = 'Failed'],
            'A failed send with a reason should be logged');
    }
}

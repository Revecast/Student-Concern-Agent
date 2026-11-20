/*****************************************************************
Name:          StudentAdvisorAlertTest
============================================================
Purpose:       Proves SUB – Alert Assigned Advisor (SCA-14), called by
               RT – Contact – Risk Crossing on an upward crossing:
               - the assigned advisor (Advisor on the Advisee Record case
                 team) gets a Record Alert, a Task and outreach log rows;
               - with no assigned advisor, the Advising Queue gets them and
                 the Advising Queue exception is logged;
               - nobody else is ever the owner or recipient (NEVER rule);
               - 200 crossings in one batch run without governor errors.
               Assumptions: the Advising Queue, the Advisee_Record case
               record type and the Advisor case team role exist (deployed
               metadata); the Risk Score Setting alert limit is 6.
============================================================
History
-------
VERSION  AUTHOR                 DATE        DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026  Created   SCA-14
1.1      Revecast Orchestrate   20/11/2026  Updated   SCA-36 QA: non-admin crossing test
*****************************************************************/
@isTest
private class StudentAdvisorAlertTest {

    private static final Integer BULK_SIZE = 200;
    private static final Decimal START_SCORE = 2;
    private static final Decimal CROSSING_SCORE = 7;

    /* Creates a standard user to act as the assigned advisor (or a bystander). */
    private static User makeUser(String alias) {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User newUser = new User(
            Alias = alias,
            Email = alias + '@advisor.jaxstate.example',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Advisor ' + alias,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = alias + '.' + System.currentTimeMillis() + '@advisor.jaxstate.example'
        );
        // Run as the current user so the setup insert does not mix with later data DML.
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert newUser;
        }
        return newUser;
    }

    /* Creates students below the alert limit, optionally with an Advisee case whose team has the advisor. */
    private static List<Contact> makeStudents(Integer count, User advisor) {
        Account adminAccount = new Account(Name = 'Alert Test Administrative Account');
        insert adminAccount;
        List<Contact> students = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            students.add(new Contact(
                FirstName = 'Student',
                LastName = 'Alert ' + i,
                AccountId = adminAccount.Id,
                Email = 'alert' + i + '@student.jaxstate.example',
                Risk_Score__c = START_SCORE,
                Risk_Reason__c = 'Missed 3 classes in 14 days.'
            ));
        }
        insert students;
        if (advisor != null) {
            Id adviseeTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('Advisee_Record').getRecordTypeId();
            List<Case> advisees = new List<Case>();
            for (Contact student : students) {
                advisees.add(new Case(RecordTypeId = adviseeTypeId, ContactId = student.Id,
                    AccountId = adminAccount.Id, Subject = 'Advisee Record'));
            }
            insert advisees;
            CaseTeamRole advisorRole = [SELECT Id FROM CaseTeamRole WHERE Name = 'Advisor' LIMIT 1];
            List<CaseTeamMember> members = new List<CaseTeamMember>();
            for (Case advisee : advisees) {
                members.add(new CaseTeamMember(ParentId = advisee.Id, MemberId = advisor.Id,
                    TeamRoleId = advisorRole.Id));
            }
            insert members;
        }
        return students;
    }

    /* Sets the score on every student in one update, inside start/stop so the flow work is measured. */
    private static void rescore(List<Contact> students, Decimal score) {
        for (Contact student : students) {
            student.Risk_Score__c = score;
        }
        Test.startTest();
        update students;
        Test.stopTest();
    }

    private static Id advisingQueueId() {
        return [SELECT Id FROM Group WHERE DeveloperName = 'Advising_Queue' AND Type = 'Queue' LIMIT 1].Id;
    }

    /* AC1: an upward crossing gives the assigned advisor a record alert, a task and log rows. */
    @isTest
    static void crossingAlertsTheAssignedAdvisor() {
        User advisor = makeUser('advone');
        List<Contact> students = makeStudents(1, advisor);
        rescore(students, CROSSING_SCORE);

        Id studentId = students[0].Id;
        List<RecordAlert> alerts = [SELECT OwnerId, Severity, IsActive, Subject FROM RecordAlert WHERE WhatId = :studentId];
        System.assertEquals(1, alerts.size(), 'One record alert should be created');
        System.assertEquals(advisor.Id, alerts[0].OwnerId, 'The alert should belong to the assigned advisor');
        System.assert(alerts[0].IsActive, 'The alert should be active');

        List<Task> tasks = [SELECT OwnerId, WhatId, Priority, ActivityDate FROM Task WHERE WhoId = :studentId];
        System.assertEquals(1, tasks.size(), 'One advisor task should be created');
        System.assertEquals(advisor.Id, tasks[0].OwnerId, 'The task should be assigned to the advisor');
        System.assertNotEquals(null, tasks[0].WhatId, 'The task should sit on the Advisee case');
        System.assertEquals(Date.today().addDays(2), tasks[0].ActivityDate, 'The task should be due in two days');

        List<Student_Outreach__c> logs = [SELECT Channel__c, Recipient_Type__c, Recipient_User__c, Exception_Used__c,
            Status__c FROM Student_Outreach__c WHERE Student__c = :studentId];
        System.assertEquals(2, logs.size(), 'Task and notification should each be logged');
        for (Student_Outreach__c logRow : logs) {
            System.assertEquals('Assigned Advisor', logRow.Recipient_Type__c, 'Logged recipient should be the advisor');
            System.assertEquals(advisor.Id, logRow.Recipient_User__c, 'Logged recipient user should be the advisor');
            System.assertEquals('None', logRow.Exception_Used__c, 'No exception is used for the advisor');
            System.assertEquals('Sent', logRow.Status__c, 'Both steps should be logged as sent');
        }
    }

    /* SCA-36 QA: the record-triggered crossing flow and its SUB – Alert Assigned Advisor subflow still run
       when a NON-admin changes the score: a Standard User with no Run Flows and no Flow Access grants,
       holding only edit access to the risk fields. */
    @isTest
    static void crossingByNonAdminStillAlertsTheAdvisor() {
        User advisor = makeUser('advnon');
        User scorer = makeUser('scorer');
        List<Contact> students = makeStudents(1, advisor);
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet dataEdit = [SELECT Id FROM PermissionSet
                WHERE Name = 'DATA_Student_Success_Create_Update' LIMIT 1];
            insert new PermissionSetAssignment(AssigneeId = scorer.Id, PermissionSetId = dataEdit.Id);
        }
        // Accounts are Private: give the scorer edit on this student's account (Contact is controlled by parent).
        insert new AccountShare(AccountId = [SELECT AccountId FROM Contact WHERE Id = :students[0].Id].AccountId,
            UserOrGroupId = scorer.Id, AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'None',
            CaseAccessLevel = 'None');
        System.assertEquals(0, [SELECT COUNT() FROM PermissionSetAssignment
            WHERE AssigneeId = :scorer.Id AND PermissionSet.PermissionsRunFlow = true], 'Scorer must not have Run Flows');

        System.runAs(scorer) {
            rescore(students, CROSSING_SCORE);
        }

        Id studentId = students[0].Id;
        System.assertEquals(1, [SELECT COUNT() FROM RecordAlert WHERE WhatId = :studentId AND OwnerId = :advisor.Id],
            'The subflow should still alert the assigned advisor');
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhoId = :studentId AND OwnerId = :advisor.Id],
            'The subflow should still create the advisor task');
    }

    /* AC2: no assigned advisor sends everything to the Advising Queue and logs the exception. */
    @isTest
    static void noAdvisorUsesTheAdvisingQueue() {
        List<Contact> students = makeStudents(1, null);
        rescore(students, CROSSING_SCORE);

        Id studentId = students[0].Id;
        Id queueId = advisingQueueId();
        System.assertEquals(queueId, [SELECT OwnerId FROM RecordAlert WHERE WhatId = :studentId].OwnerId,
            'The alert should go to the Advising Queue');
        System.assertEquals(queueId, [SELECT OwnerId FROM Task WHERE WhoId = :studentId].OwnerId,
            'The task should go to the Advising Queue');

        List<Student_Outreach__c> logs = [SELECT Recipient_Type__c, Exception_Used__c, Status__c, Failure_Reason__c
            FROM Student_Outreach__c WHERE Student__c = :studentId];
        System.assertEquals(3, logs.size(), 'Task, notification and the exception should be logged');
        Integer exceptionRows = 0;
        for (Student_Outreach__c logRow : logs) {
            System.assertEquals('Advising Queue', logRow.Recipient_Type__c, 'Logged recipient should be the queue');
            System.assertEquals('Advising Queue', logRow.Exception_Used__c, 'The queue exception should be recorded');
            if (logRow.Status__c == 'Skipped') {
                exceptionRows++;
                System.assert(logRow.Failure_Reason__c.contains('No assigned advisor'), 'The reason should say why');
            }
        }
        System.assertEquals(1, exceptionRows, 'Exactly one exception row should explain the fallback');
    }

    /* AC3 (NEVER rule): a bystander who owns the student's account gets nothing; only the advisor does. */
    @isTest
    static void nobodyButTheAdvisorIsAlerted() {
        User advisor = makeUser('advtwo');
        User bystander = makeUser('bystnd');
        List<Contact> students = makeStudents(1, advisor);
        Account studentAccount = [SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :students[0].Id)];
        studentAccount.OwnerId = bystander.Id;
        update studentAccount;
        rescore(students, CROSSING_SCORE);

        Id studentId = students[0].Id;
        for (RecordAlert alert : [SELECT OwnerId FROM RecordAlert WHERE WhatId = :studentId]) {
            System.assertEquals(advisor.Id, alert.OwnerId, 'Only the assigned advisor may own an alert');
        }
        for (Task followUp : [SELECT OwnerId FROM Task WHERE WhoId = :studentId]) {
            System.assertEquals(advisor.Id, followUp.OwnerId, 'Only the assigned advisor may own the task');
        }
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE OwnerId = :bystander.Id],
            'The account owner must not get a task');
        System.assertEquals(0, [SELECT COUNT() FROM Student_Outreach__c
            WHERE Student__c = :studentId AND Recipient_Type__c NOT IN ('Assigned Advisor')],
            'No other recipient type may appear in the log');
    }

    /* A score that does not cross the limit creates nothing. */
    @isTest
    static void noCrossingCreatesNothing() {
        User advisor = makeUser('advthr');
        List<Contact> students = makeStudents(1, advisor);
        rescore(students, 4);
        Id studentId = students[0].Id;
        System.assertEquals(0, [SELECT COUNT() FROM RecordAlert WHERE WhatId = :studentId], 'No alert below the limit');
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhoId = :studentId], 'No task below the limit');
    }

    /* Bulk: 200 students with an advisor cross in one nightly batch without governor errors. */
    @isTest
    static void bulkCrossingAlertsEveryStudent() {
        User advisor = makeUser('advblk');
        List<Contact> students = makeStudents(BULK_SIZE, advisor);
        rescore(students, CROSSING_SCORE);
        System.assertEquals(BULK_SIZE, [SELECT COUNT() FROM RecordAlert WHERE WhatId IN :students AND OwnerId = :advisor.Id],
            'Every crossing student should get an advisor alert');
        System.assertEquals(BULK_SIZE, [SELECT COUNT() FROM Task WHERE WhoId IN :students AND OwnerId = :advisor.Id],
            'Every crossing student should get an advisor task');
        System.assertEquals(0, [SELECT COUNT() FROM Student_Outreach__c WHERE Student__c IN :students AND Status__c = 'Failed'],
            'No step should fail in bulk');
    }
}

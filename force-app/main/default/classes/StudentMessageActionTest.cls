/*****************************************************************
Name:          StudentMessageActionTest
============================================================
Purpose:       Proves SUB – Send Student Message (SCA-36), the only
               messaging action the agents use. It has no recipient or
               address input, so the NEVER rule (ADR-001) holds however
               the agent is asked:
               - Student: email to the student's own record email;
               - Assigned Advisor: email to the advisor on the Advisee
                 case team, or a Task to the Advising Queue (exception
                 logged) when there is none;
               - Counseling Center: only on a crisis, as an urgent Task
                 to the Counseling Center queue (Crisis logged);
               - anyone else ("my professor", "my dad") is refused, with
                 no email, task or log.
               Every send, skip and failure is logged (SCA-37).
               Emails are never delivered in tests; each send leaves an
               EmailMessage, which the tests check (To address, count).
============================================================
History
-------
VERSION  AUTHOR                 DATE        DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026  Created   SCA-36
1.1      Revecast Orchestrate   20/11/2026  Updated   SCA-36 QA: runs as a user with the Flow Access grant
*****************************************************************/
@isTest
private class StudentMessageActionTest {

    private static final String SUBJECT = 'Checking in';
    private static final String BODY = 'Hi, checking in on how your term is going.';

    /* Creates a standard user to act as the assigned advisor. */
    private static User makeAdvisor() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User advisor = new User(
            Alias = 'msgadv',
            Email = 'msgadv@advisor.jaxstate.example',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Message Advisor',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'msgadv.' + System.currentTimeMillis() + '@advisor.jaxstate.example'
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert advisor;
        }
        return advisor;
    }

    private static User cachedSender;

    /* The calling user: a standard user with SYS – Student Concern Automation, which grants
       Flow Access to the flow (it requires it: isAdditionalPermissionRequiredToRun, SCA-36 QA fix). */
    private static User sender() {
        if (cachedSender == null) {
            Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            cachedSender = new User(Alias = 'msgsnd', Email = 'msgsnd@automation.jaxstate.example',
                EmailEncodingKey = 'UTF-8', LastName = 'Message Sender', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = standardProfile.Id, TimeZoneSidKey = 'America/New_York',
                Username = 'msgsnd.' + System.currentTimeMillis() + '@automation.jaxstate.example');
            System.runAs(new User(Id = UserInfo.getUserId())) {
                insert cachedSender;
                PermissionSet automation = [SELECT Id FROM PermissionSet
                    WHERE Name = 'SYS_Student_Concern_Automation' LIMIT 1];
                insert new PermissionSetAssignment(AssigneeId = cachedSender.Id, PermissionSetId = automation.Id);
            }
        }
        return cachedSender;
    }

    /* Creates one student, optionally with an email and an Advisee case whose team has the advisor. */
    private static Contact makeStudent(Boolean withEmail, User advisor) {
        Account adminAccount = new Account(Name = 'Message Test Administrative Account');
        insert adminAccount;
        Contact student = new Contact(FirstName = 'Jordan', LastName = 'Message Test', AccountId = adminAccount.Id,
            Email = withEmail ? 'jordan.msg@student.jaxstate.example' : null, Risk_Score__c = 7);
        insert student;
        if (advisor != null) {
            Id adviseeTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                .get('Advisee_Record').getRecordTypeId();
            Case advisee = new Case(RecordTypeId = adviseeTypeId, ContactId = student.Id,
                AccountId = adminAccount.Id, Subject = 'Advisee Record');
            insert advisee;
            CaseTeamRole advisorRole = [SELECT Id FROM CaseTeamRole WHERE Name = 'Advisor' LIMIT 1];
            insert new CaseTeamMember(ParentId = advisee.Id, MemberId = advisor.Id, TeamRoleId = advisorRole.Id);
        }
        return student;
    }

    /* Result of one call: the flow's outputs. */
    private class Outcome {
        Boolean sent;
        String result;
    }

    /* Runs the flow once. */
    private static Outcome send(Id studentId, String role, Boolean isCrisis) {
        Map<String, Object> inputs = new Map<String, Object>{
            'varT_StudentId' => studentId,
            'varP_RecipientRole' => role,
            'varT_Subject' => SUBJECT,
            'varT_Body' => BODY,
            'varB_IsCrisis' => isCrisis
        };
        Outcome outcome = new Outcome();
        User caller = sender();
        Flow.Interview.SUB_Send_Student_Message interview = new Flow.Interview.SUB_Send_Student_Message(inputs);
        Test.startTest();
        System.runAs(caller) {
            interview.start();
        }
        Test.stopTest();
        outcome.sent = (Boolean) interview.getVariableValue('varB_Sent');
        outcome.result = (String) interview.getVariableValue('varT_Result');
        return outcome;
    }

    private static List<Student_Outreach__c> logsFor(Id studentId) {
        return [SELECT Recipient_Type__c, Exception_Used__c, Channel__c, Status__c, Recipient_User__c, Failure_Reason__c
                FROM Student_Outreach__c WHERE Student__c = :studentId];
    }

    private static Id queueId(String developerName) {
        return [SELECT Id FROM Group WHERE DeveloperName = :developerName AND Type = 'Queue' LIMIT 1].Id;
    }

    /* Student role: one email to the student's own address, logged as Student / None / Email / Sent. */
    @isTest
    static void studentRoleEmailsTheStudentOnly() {
        Contact student = makeStudent(true, null);
        Outcome outcome = send(student.Id, 'Student', false);

        System.assert(outcome.sent, 'The message should be sent');
        List<EmailMessage> emails = [SELECT ToAddress, Subject FROM EmailMessage];
        System.assertEquals(1, emails.size(), 'Exactly one email should be sent');
        System.assertEquals(student.Email, emails[0].ToAddress, 'It should go only to the student\'s own email');
        List<Student_Outreach__c> logs = logsFor(student.Id);
        System.assertEquals(1, logs.size(), 'One log row');
        System.assertEquals('Student', logs[0].Recipient_Type__c, 'Recipient should be the student');
        System.assertEquals('None', logs[0].Exception_Used__c, 'No exception for the student');
        System.assertEquals('Email', logs[0].Channel__c, 'Channel should be Email');
        System.assertEquals('Sent', logs[0].Status__c, 'Status should be Sent');
    }

    /* Assigned Advisor role: one email to the advisor on the Advisee case team. */
    @isTest
    static void advisorRoleEmailsTheAssignedAdvisor() {
        User advisor = makeAdvisor();
        Contact student = makeStudent(true, advisor);
        Outcome outcome = send(student.Id, 'Assigned Advisor', false);

        System.assert(outcome.sent, 'The message should be sent');
        List<EmailMessage> emails = [SELECT ToAddress FROM EmailMessage];
        System.assertEquals(1, emails.size(), 'Exactly one email should be sent');
        System.assertEquals(advisor.Email, emails[0].ToAddress, 'It should go only to the assigned advisor');
        List<Student_Outreach__c> logs = logsFor(student.Id);
        System.assertEquals(1, logs.size(), 'One log row');
        System.assertEquals('Assigned Advisor', logs[0].Recipient_Type__c, 'Recipient should be the advisor');
        System.assertEquals(advisor.Id, logs[0].Recipient_User__c, 'The log should name the advisor');
        System.assertEquals('None', logs[0].Exception_Used__c, 'No exception for the assigned advisor');
    }

    /* No assigned advisor: a Task for the Advising Queue, no email, exception logged. */
    @isTest
    static void noAdvisorFallsBackToAdvisingQueue() {
        Contact student = makeStudent(true, null);
        Outcome outcome = send(student.Id, 'Assigned Advisor', false);

        System.assert(outcome.sent, 'The message should go to the queue');
        System.assertEquals(0, [SELECT COUNT() FROM EmailMessage], 'No email should be sent');
        List<Task> tasks = [SELECT OwnerId FROM Task WHERE WhoId = :student.Id];
        System.assertEquals(1, tasks.size(), 'One queue task');
        System.assertEquals(queueId('Advising_Queue'), tasks[0].OwnerId, 'Task should belong to the Advising Queue');
        List<Student_Outreach__c> logs = logsFor(student.Id);
        System.assertEquals('Advising Queue', logs[0].Recipient_Type__c, 'Recipient should be the queue');
        System.assertEquals('Advising Queue', logs[0].Exception_Used__c, 'The queue exception should be logged');
        System.assertEquals('Task', logs[0].Channel__c, 'Channel should be Task');
    }

    /* Crisis: an urgent Task for the Counseling Center queue, Crisis exception logged. */
    @isTest
    static void crisisGoesToCounselingCenter() {
        Contact student = makeStudent(true, null);
        Outcome outcome = send(student.Id, 'Counseling Center', true);

        System.assert(outcome.sent, 'The crisis handoff should be created');
        System.assertEquals(0, [SELECT COUNT() FROM EmailMessage], 'No email should be sent');
        List<Task> tasks = [SELECT OwnerId, Priority, ActivityDate FROM Task WHERE WhoId = :student.Id];
        System.assertEquals(1, tasks.size(), 'One counseling task');
        System.assertEquals(queueId('Counseling_Center'), tasks[0].OwnerId, 'Task should belong to the Counseling Center');
        System.assertEquals('High', tasks[0].Priority, 'Crisis task should be urgent');
        System.assertEquals(Date.today(), tasks[0].ActivityDate, 'Crisis task should be due today');
        List<Student_Outreach__c> logs = logsFor(student.Id);
        System.assertEquals(2, logs.size(), 'One Task row and one notice row');
        Integer taskRows = 0;
        Integer noticeRows = 0;
        for (Student_Outreach__c log : logs) {
            System.assertEquals('Counseling Center', log.Recipient_Type__c, 'Recipient should be counseling');
            System.assertEquals('Crisis', log.Exception_Used__c, 'The Crisis exception should be logged');
            System.assertEquals('Sent', log.Status__c, 'Both rows should be Sent, not Failed: ' + log.Failure_Reason__c);
            if (log.Channel__c == 'Task') {
                taskRows++;
            } else if (log.Channel__c == 'In-App Notification') {
                noticeRows++;
            }
        }
        System.assertEquals(1, taskRows, 'The crisis Task should be logged once');
        System.assertEquals(1, noticeRows, 'The Counseling Center notice should be logged once');
    }

    /* The Counseling Center notice is sent only after a real crisis Task: no notice row
       on any other send, and none on a refused send (checked in counselingWithoutCrisisIsRefused). */
    @isTest
    static void noCounselingNoticeOnOtherSends() {
        Contact student = makeStudent(true, null);
        Outcome outcome = send(student.Id, 'Assigned Advisor', false);

        System.assert(outcome.sent, 'The Advising Queue task should be created');
        System.assertEquals(0, [SELECT COUNT() FROM Student_Outreach__c
            WHERE Student__c = :student.Id AND Channel__c = 'In-App Notification'],
            'No notice should be sent for a non-crisis send');
    }

    /* Counseling Center without a crisis is refused: nothing sent, created or logged. */
    @isTest
    static void counselingWithoutCrisisIsRefused() {
        Contact student = makeStudent(true, null);
        Outcome outcome = send(student.Id, 'Counseling Center', false);

        System.assert(!outcome.sent, 'Nothing should be sent');
        System.assert(outcome.result.startsWith('Not sent'), 'The agent should be told it was refused');
        System.assertEquals(0, [SELECT COUNT() FROM EmailMessage], 'No email');
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhoId = :student.Id], 'No task');
        System.assertEquals(0, logsFor(student.Id).size(), 'No outreach row');
    }

    /* "Text my professor" / "email my dad": any other role is refused. */
    @isTest
    static void otherRecipientsAreRefused() {
        Contact student = makeStudent(true, null);
        User caller = sender();
        for (String role : new List<String>{ 'Professor', 'Parent', '' }) {
            Map<String, Object> inputs = new Map<String, Object>{
                'varT_StudentId' => student.Id, 'varP_RecipientRole' => role,
                'varT_Subject' => SUBJECT, 'varT_Body' => BODY, 'varB_IsCrisis' => true
            };
            Flow.Interview.SUB_Send_Student_Message interview = new Flow.Interview.SUB_Send_Student_Message(inputs);
            System.runAs(caller) {
                interview.start();
            }
            System.assertEquals(false, interview.getVariableValue('varB_Sent'), 'Role "' + role + '" must be refused');
        }
        System.assertEquals(0, [SELECT COUNT() FROM EmailMessage], 'No email for any refused role');
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhoId = :student.Id], 'No task for any refused role');
        System.assertEquals(0, logsFor(student.Id).size(), 'No outreach rows');
    }

    /* A student with no email is skipped and the reason logged. */
    @isTest
    static void studentWithoutEmailIsSkippedAndLogged() {
        Contact student = makeStudent(false, null);
        Outcome outcome = send(student.Id, 'Student', false);

        System.assert(!outcome.sent, 'Nothing should be sent');
        System.assertEquals(0, [SELECT COUNT() FROM EmailMessage], 'No email');
        List<Student_Outreach__c> logs = logsFor(student.Id);
        System.assertEquals(1, logs.size(), 'One log row');
        System.assertEquals('Skipped', logs[0].Status__c, 'Status should be Skipped');
        System.assertNotEquals(null, logs[0].Failure_Reason__c, 'The reason should be recorded');
    }

    /* A user without the Flow Access grant cannot run the send flow at all (SCA-36 QA fix). */
    @isTest
    static void userWithoutFlowAccessIsRefused() {
        User advisor = makeAdvisor();
        Contact student = makeStudent(true, advisor);
        Flow.Interview.SUB_Send_Student_Message interview = new Flow.Interview.SUB_Send_Student_Message(
            new Map<String, Object>{ 'varT_StudentId' => student.Id, 'varP_RecipientRole' => 'Student',
                'varT_Subject' => SUBJECT, 'varT_Body' => BODY, 'varB_IsCrisis' => false });
        Boolean refused = false;
        System.runAs(advisor) {
            try {
                interview.start();
            } catch (System.NoAccessException e) {
                refused = true;
            }
        }
        System.assert(refused, 'Without the Flow Access grant the flow must not run');
        System.assertEquals(0, [SELECT COUNT() FROM EmailMessage], 'Nothing is sent');
    }
}

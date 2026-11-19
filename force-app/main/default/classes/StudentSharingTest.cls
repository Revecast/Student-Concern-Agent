/*****************************************************************
Name:          StudentSharingTest
============================================================
Purpose:       Proves "own students only" (SCA-5 AC2, ADR-013) with
               System.runAs. Data assumptions: Account is Private and
               Contact is Controlled by Parent in the org; the Advisee
               Record case record type exists (SCA-8). Two fictional
               students, A and B; the advisor is on A's account team
               (Read) and A's Advisee case team only.
               Expected: the advisor sees A's Contact, Advisee case,
               risk score and outreach rows, and nothing of B's; the
               agent's running user sees both; the sharing flow gives
               the advisor a Read share on A's new outreach rows (bulk:
               40 rows) and none on B's.
============================================================
History
-------
VERSION  AUTHOR                  DATE         DETAIL    DESCRIPTION
1.0      Revecast Orchestrate    19/11/2026   Created   SCA-5 / ADR-013
*****************************************************************/
@isTest
private class StudentSharingTest {

    private static final String BASE_PROFILE = 'Standard User';
    private static final Integer ROWS_PER_STUDENT = 20;

    // Creates an active user on the base profile (no data access of its own).
    private static User makeUser(String alias) {
        Profile base = [SELECT Id FROM Profile WHERE Name = :BASE_PROFILE LIMIT 1];
        User testUser = new User(Alias = alias, Email = alias + '@example.edu', EmailEncodingKey = 'UTF-8',
            LastName = 'Sharing ' + alias, LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = base.Id, TimeZoneSidKey = 'America/New_York',
            Username = alias + '.' + String.valueOf(Crypto.getRandomInteger()).remove('-') + '@sca.test');
        insert testUser;
        return testUser;
    }

    // Assigns a permission set group after recalculating it.
    private static void assignGroup(Id userId, String groupName) {
        PermissionSetGroup grp = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :groupName LIMIT 1];
        Test.calculatePermissionSetGroup(grp.Id);
        insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetGroupId = grp.Id);
    }

    // Returns the Advisor case team role, creating it if the org has none.
    private static CaseTeamRole advisorRole() {
        List<CaseTeamRole> roles = [SELECT Id FROM CaseTeamRole WHERE Name = 'Advisor' LIMIT 1];
        if (!roles.isEmpty()) {
            return roles[0];
        }
        CaseTeamRole role = new CaseTeamRole(Name = 'Advisor', AccessLevel = 'Edit');
        insert role;
        return role;
    }

    // Builds a valid outreach row to the student (the NEVER rule allows Student + None).
    private static Student_Outreach__c outreach(Id studentId) {
        return new Student_Outreach__c(Student__c = studentId, Channel__c = 'Email',
            Recipient_Type__c = 'Student', Exception_Used__c = 'None', Status__c = 'Sent', Sent_At__c = System.now());
    }

    /*
     * Full scenario: advisor assigned to A only. Advisor sees A's records only;
     * the agent user sees both; the flow shares A's outreach rows with the advisor.
     */
    @isTest
    static void advisorSeesOnlyAssignedStudents() {
        User advisor = makeUser('shradv');
        User agentUser = makeUser('shragt');
        CaseTeamRole role;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            assignGroup(advisor.Id, 'Student_Success_Advisor');
            assignGroup(agentUser.Id, 'Student_Concern_Agent_User');
            role = advisorRole();
        }

        // Two students, each with an administrative account and an Advisee Record.
        Account accountA = new Account(Name = 'Sharing Test A Administrative Account');
        Account accountB = new Account(Name = 'Sharing Test B Administrative Account');
        insert new List<Account>{ accountA, accountB };
        Contact studentA = new Contact(LastName = 'Student A', AccountId = accountA.Id, Risk_Score__c = 7);
        Contact studentB = new Contact(LastName = 'Student B', AccountId = accountB.Id, Risk_Score__c = 3);
        insert new List<Contact>{ studentA, studentB };
        Id adviseeType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Advisee_Record').getRecordTypeId();
        Case caseA = new Case(RecordTypeId = adviseeType, ContactId = studentA.Id, AccountId = accountA.Id, Status = 'Working', Subject = 'Advisee Record - A');
        Case caseB = new Case(RecordTypeId = adviseeType, ContactId = studentB.Id, AccountId = accountB.Id, Status = 'Working', Subject = 'Advisee Record - B');
        insert new List<Case>{ caseA, caseB };

        // The advisor is assigned to A only: account team (Read) + Advisee case team.
        insert new AccountTeamMember(AccountId = accountA.Id, UserId = advisor.Id, TeamMemberRole = 'Advisor',
            AccountAccessLevel = 'Read', CaseAccessLevel = 'None', OpportunityAccessLevel = 'None');
        insert new CaseTeamMember(ParentId = caseA.Id, MemberId = advisor.Id, TeamRoleId = role.Id);

        // Bulk outreach rows for both students; the sharing flow runs on insert.
        List<Student_Outreach__c> rows = new List<Student_Outreach__c>();
        for (Integer i = 0; i < ROWS_PER_STUDENT; i++) {
            rows.add(outreach(studentA.Id));
            rows.add(outreach(studentB.Id));
        }
        Test.startTest();
        insert rows;
        Test.stopTest();

        // The flow created one Read share per A row for the advisor, and none on B rows.
        System.assertEquals(ROWS_PER_STUDENT, [SELECT COUNT() FROM Student_Outreach__Share
            WHERE UserOrGroupId = :advisor.Id AND RowCause = 'Manual' AND AccessLevel = 'Read'],
            'One Read share per outreach row of the assigned student');

        System.runAs(advisor) {
            List<Contact> visible = [SELECT Id, Risk_Score__c FROM Contact WHERE Id IN :new List<Id>{ studentA.Id, studentB.Id }];
            System.assertEquals(1, visible.size(), 'Advisor sees only the assigned student');
            System.assertEquals(studentA.Id, visible[0].Id, 'The visible student is A');
            System.assertEquals(7, visible[0].Risk_Score__c, 'Advisor can read the risk score');
            System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Id IN :new List<Id>{ caseA.Id, caseB.Id }],
                'Advisor sees only the assigned Advisee Record');
            System.assertEquals(ROWS_PER_STUDENT, [SELECT COUNT() FROM Student_Outreach__c],
                'Advisor sees only the assigned student\'s outreach rows');
            System.assertEquals(0, [SELECT COUNT() FROM Student_Outreach__c WHERE Student__c = :studentB.Id],
                'Advisor sees none of the other student\'s outreach rows');
        }

        System.runAs(agentUser) {
            System.assertEquals(2, [SELECT COUNT() FROM Contact WHERE Id IN :new List<Id>{ studentA.Id, studentB.Id }],
                'The agent user sees every student');
            System.assertEquals(2 * ROWS_PER_STUDENT, [SELECT COUNT() FROM Student_Outreach__c],
                'The agent user sees every outreach row');
        }
    }

    /*
     * Negative: an outreach row for a student with no Advisee Record creates no
     * share and no failure reason.
     */
    @isTest
    static void noAdviseeRecordMeansNoShare() {
        Account school = new Account(Name = 'Sharing Test C Administrative Account');
        insert school;
        Contact student = new Contact(LastName = 'Student C', AccountId = school.Id);
        insert student;

        Test.startTest();
        Student_Outreach__c row = outreach(student.Id);
        insert row;
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Student_Outreach__Share WHERE ParentId = :row.Id AND RowCause = 'Manual'],
            'No advisor, so no manual share');
        System.assertEquals(null, [SELECT Failure_Reason__c FROM Student_Outreach__c WHERE Id = :row.Id].Failure_Reason__c,
            'No failure is recorded when there is simply no advisor');
    }
}

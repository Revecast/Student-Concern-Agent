/*****************************************************************
Name:          StudentSuccessAccessTest
============================================================
Purpose:       Proves the least-privilege access model for the Student
               Concern Agent (SCA-5) with System.runAs:
               - an advisor (Student Success Advisor group) can READ the
                 risk fields, outreach log and classroom activity, but not
                 edit them;
               - a user without the group cannot see the risk fields at all
                 (SCA-4 AC2);
               - the agent's running user (Student Concern Agent User group)
                 can create outreach log rows and update risk fields.
               Test users are created in the test only; no real users or data.
============================================================
History
-------
VERSION  AUTHOR                 DATE         DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026   Created   SCA-5
*****************************************************************/
@isTest
private class StudentSuccessAccessTest {

    // Profile with no field access to the custom risk fields of its own.
    private static final String BASE_PROFILE = 'Standard User';

    /*****************************************************************
    Purpose:  Creates an active test user on the base profile.
    Parameters: alias - short unique alias for the user
    Returns:  The inserted User.
    *****************************************************************/
    private static User makeUser(String alias) {
        Profile base = [SELECT Id FROM Profile WHERE Name = :BASE_PROFILE LIMIT 1];
        User testUser = new User(
            Alias = alias,
            Email = alias + '@example.edu',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Access ' + alias,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = base.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = alias + '.' + String.valueOf(Crypto.getRandomInteger()).remove('-') + '@sca.test'
        );
        insert testUser;
        return testUser;
    }

    /*****************************************************************
    Purpose:  Assigns a permission set group to a user, recalculating the
              group first so the test does not depend on its org status.
    Parameters: userId - user to assign
                groupName - PermissionSetGroup DeveloperName
    *****************************************************************/
    private static void assignGroup(Id userId, String groupName) {
        PermissionSetGroup grp = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :groupName LIMIT 1];
        Test.calculatePermissionSetGroup(grp.Id);
        insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetGroupId = grp.Id);
    }

    // Advisor: read, but never edit, the student-success data.
    @isTest
    static void advisorCanReadButNotEdit() {
        User advisor = makeUser('scaadv');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Setup-object DML is isolated from the runAs user below.
            assignGroup(advisor.Id, 'Student_Success_Advisor');
        }

        System.runAs(advisor) {
            Schema.DescribeFieldResult score = Contact.Risk_Score__c.getDescribe();
            System.assert(score.isAccessible(), 'Advisor should read Risk Score');
            System.assert(!score.isUpdateable(), 'Advisor must not edit Risk Score');
            System.assert(Contact.Risk_Reason__c.getDescribe().isAccessible(), 'Advisor should read Risk Reason');
            System.assert(Contact.Risk_Last_Alerted_Date__c.getDescribe().isAccessible(),
                'Advisor should read Risk Last Alerted Date');

            Schema.DescribeSObjectResult outreach = Student_Outreach__c.SObjectType.getDescribe();
            System.assert(outreach.isAccessible(), 'Advisor should read the outreach log');
            System.assert(!outreach.isCreateable(), 'Advisor must not create outreach log rows');
            System.assert(!outreach.isDeletable(), 'Advisor must not delete outreach log rows');

            System.assert(Classroom_Activity__c.SObjectType.getDescribe().isAccessible(),
                'Advisor should read classroom activity');
            System.assert(Classroom_Activity__c.Current_Grade__c.getDescribe().isAccessible(),
                'Advisor should read grades');
        }
    }

    // No group: the risk fields and the outreach log stay hidden (SCA-4 AC2).
    @isTest
    static void userWithoutGroupCannotSeeRiskData() {
        User outsider = makeUser('scanone');

        System.runAs(outsider) {
            System.assert(!Contact.Risk_Score__c.getDescribe().isAccessible(),
                'Risk Score must be hidden without the permission set');
            System.assert(!Contact.Risk_Reason__c.getDescribe().isAccessible(),
                'Risk Reason must be hidden without the permission set');
            System.assert(!Student_Outreach__c.SObjectType.getDescribe().isAccessible(),
                'Outreach log must be hidden without the permission set');
        }
    }

    // Agent user: can write the outreach log and risk fields, cannot delete.
    @isTest
    static void agentUserCanWriteLog() {
        User agentUser = makeUser('scaagt');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            assignGroup(agentUser.Id, 'Student_Concern_Agent_User');
        }

        System.runAs(agentUser) {
            System.assert(Student_Outreach__c.SObjectType.getDescribe().isCreateable(),
                'Agent user should create outreach log rows');
            System.assert(!Student_Outreach__c.SObjectType.getDescribe().isDeletable(),
                'Agent user must not delete outreach log rows');
            System.assert(Contact.Risk_Score__c.getDescribe().isUpdateable(),
                'Agent user should update the risk score');
        }
    }
}

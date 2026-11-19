/*****************************************************************
Name:          StudentFindMyStudentTest
============================================================
Purpose:       Proves SUB – Find My Student, the gate for the advisor
               agent (SCA-22, SCA-23): a student is returned only when
               the running user is the Advisor on that student's
               Advisee Record case team.
               - own student: returned, assigned = true;
               - another advisor's student: not returned, generic result;
               - a name nobody has: same generic result (existence is
                 not confirmed);
               - two own students with the same name: nothing returned,
                 the agent asks for more detail.
============================================================
History
-------
VERSION  AUTHOR                 DATE        DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026  Created   SCA-22
*****************************************************************/
@isTest
private class StudentFindMyStudentTest {

    private static final String NOT_ASSIGNED = 'That student is not on your caseload';

    /* Creates a standard user to act as an advisor. */
    private static User makeAdvisor(String alias) {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User advisor = new User(Alias = alias, Email = alias + '@advisor.jaxstate.example', EmailEncodingKey = 'UTF-8',
            LastName = 'Advisor ' + alias, LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id, TimeZoneSidKey = 'America/New_York',
            Username = alias + '.' + System.currentTimeMillis() + '@advisor.jaxstate.example');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert advisor;
        }
        return advisor;
    }

    /* Creates a student with an Advisee Record whose case team has the advisor. */
    private static Contact makeStudent(String firstName, String lastName, User advisor) {
        Account adminAccount = new Account(Name = firstName + ' ' + lastName + ' Administrative Account');
        insert adminAccount;
        Contact student = new Contact(FirstName = firstName, LastName = lastName, AccountId = adminAccount.Id);
        insert student;
        Id adviseeTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Advisee_Record').getRecordTypeId();
        Case advisee = new Case(RecordTypeId = adviseeTypeId, ContactId = student.Id, AccountId = adminAccount.Id,
            Subject = 'Advisee Record');
        insert advisee;
        CaseTeamRole advisorRole = [SELECT Id FROM CaseTeamRole WHERE Name = 'Advisor' LIMIT 1];
        insert new CaseTeamMember(ParentId = advisee.Id, MemberId = advisor.Id, TeamRoleId = advisorRole.Id);
        return student;
    }

    /* Runs the gate as the given user. */
    private static Flow.Interview.SUB_Find_My_Student find(User runningUser, String studentName) {
        Flow.Interview.SUB_Find_My_Student interview = new Flow.Interview.SUB_Find_My_Student(
            new Map<String, Object>{ 'varT_StudentName' => studentName });
        System.runAs(runningUser) {
            interview.start();
        }
        return interview;
    }

    @isTest
    static void advisorFindsOwnStudent() {
        User mine = makeAdvisor('fmsmine');
        Contact student = makeStudent('Jordan', 'Gatetest', mine);
        Test.startTest();
        Flow.Interview.SUB_Find_My_Student interview = find(mine, 'Jordan Gatetest');
        Test.stopTest();
        System.assertEquals(true, interview.getVariableValue('varB_IsAssigned'), 'Own student should pass the gate');
        System.assertEquals(student.Id, interview.getVariableValue('varT_StudentId'), 'The student Id should be returned');
        System.assertEquals('OK', interview.getVariableValue('varT_Result'), 'Result should be OK');
    }

    @isTest
    static void otherAdvisorsStudentIsDeclined() {
        User mine = makeAdvisor('fmsmine');
        User other = makeAdvisor('fmsothr');
        makeStudent('Riley', 'Gatetest', other);
        Test.startTest();
        Flow.Interview.SUB_Find_My_Student interview = find(mine, 'Riley Gatetest');
        Test.stopTest();
        System.assertEquals(false, interview.getVariableValue('varB_IsAssigned'), 'Another advisor\'s student must not pass');
        System.assert(String.isBlank((String) interview.getVariableValue('varT_StudentId')), 'No Id may be returned');
        System.assert(((String) interview.getVariableValue('varT_Result')).startsWith(NOT_ASSIGNED), 'Generic decline');
    }

    @isTest
    static void unknownNameGetsTheSameDecline() {
        User mine = makeAdvisor('fmsmine');
        Test.startTest();
        Flow.Interview.SUB_Find_My_Student interview = find(mine, 'Nobody Withthisname');
        Test.stopTest();
        System.assertEquals(false, interview.getVariableValue('varB_IsAssigned'), 'Unknown name must not pass');
        System.assert(((String) interview.getVariableValue('varT_Result')).startsWith(NOT_ASSIGNED),
            'Same wording as another advisor\'s student, so existence is not confirmed');
    }

    @isTest
    static void twoOwnStudentsWithSameNameReturnNothing() {
        User mine = makeAdvisor('fmsmine');
        makeStudent('Sam', 'Gatetest', mine);
        makeStudent('Sam', 'Gatetest', mine);
        Test.startTest();
        Flow.Interview.SUB_Find_My_Student interview = find(mine, 'Sam Gatetest');
        Test.stopTest();
        System.assertEquals(false, interview.getVariableValue('varB_IsAssigned'), 'Ambiguous name must not pass');
        System.assert(String.isBlank((String) interview.getVariableValue('varT_StudentId')), 'No Id may be returned');
        System.assert(((String) interview.getVariableValue('varT_Result')).startsWith('More than one'), 'Asks for detail');
    }
}

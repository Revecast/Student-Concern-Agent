/*****************************************************************
Name:          StudentLiveAssignmentsTest
============================================================
Purpose:       Proves get_live_assignments(student), the flow
               SUB – Get Live Assignments (SCA-31):
               - a verified student gets the sample assignments for
                 their own courses only, in the fixed interface shape
                 "Course: Title (type), due YYYY-MM-DD, N points";
               - an unverified student gets nothing and no classroom
                 data is read (FERPA);
               - a student with no courses is told there is nothing due.
               Assumptions: the Simulated Assignment custom metadata
               holds 2 samples each for BIO 101, ENG 101 and MATH 110.
============================================================
History
-------
VERSION  AUTHOR                 DATE        DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026  Created   SCA-31
*****************************************************************/
@isTest
private class StudentLiveAssignmentsTest {

    private static final String BIO = 'BIO 101 - Introduction to Biology';
    private static final String MATH = 'MATH 110 - College Algebra';

    /* Creates a student enrolled (in the simulated classroom system) in the given courses. */
    private static Contact makeStudent(List<String> courseNames) {
        Account adminAccount = new Account(Name = 'Assignments Test Administrative Account');
        insert adminAccount;
        Contact student = new Contact(FirstName = 'Jordan', LastName = 'Assignments Test', AccountId = adminAccount.Id);
        insert student;
        List<Classroom_Activity__c> activities = new List<Classroom_Activity__c>();
        for (String courseName : courseNames) {
            activities.add(new Classroom_Activity__c(Student__c = student.Id, Course_Name__c = courseName,
                External_Key__c = student.Id + '|' + courseName, Current_Grade__c = 80, Source_System__c = 'Simulated'));
        }
        insert activities;
        return student;
    }

    /* Runs the interface flow and returns it for reading outputs. */
    private static Flow.Interview.SUB_Get_Live_Assignments run(Id studentId, Boolean isVerified) {
        Flow.Interview.SUB_Get_Live_Assignments interview = new Flow.Interview.SUB_Get_Live_Assignments(
            new Map<String, Object>{ 'varT_StudentId' => studentId, 'varB_IsVerified' => isVerified });
        Test.startTest();
        interview.start();
        Test.stopTest();
        return interview;
    }

    /* AC1: a verified student gets their own courses' assignments in the fixed shape. */
    @isTest
    static void verifiedStudentGetsOwnCoursesOnly() {
        Contact student = makeStudent(new List<String>{ BIO, MATH });
        Flow.Interview.SUB_Get_Live_Assignments interview = run(student.Id, true);

        Decimal count = (Decimal) interview.getVariableValue('varN_AssignmentCount');
        String assignments = (String) interview.getVariableValue('varT_Assignments');
        System.assertEquals(4, count, 'Two samples each for BIO 101 and MATH 110');
        System.assertEquals('OK', interview.getVariableValue('varT_Result'), 'Result should be OK');
        System.assert(assignments.contains('Lab report 4'), 'BIO 101 work should be listed');
        System.assert(assignments.contains('Problem set 7'), 'MATH 110 work should be listed');
        System.assert(!assignments.contains('Essay 2'), 'ENG 101 work must not appear for a student not in ENG 101');
        System.assertEquals(4, assignments.split('; ').size(), 'Four entries separated by "; "');
        String dueIn3 = String.valueOf(Date.today().addDays(3));
        System.assert(assignments.contains(BIO + ': Lab report 4: Cellular respiration (lab report), due ' + dueIn3 + ', 20 points'),
            'Entries follow the fixed shape: ' + assignments);
        System.assert(!assignments.endsWith('; '), 'No trailing separator');
    }

    /* AC2: an unverified student gets nothing. */
    @isTest
    static void unverifiedStudentGetsNothing() {
        Contact student = makeStudent(new List<String>{ BIO });
        Flow.Interview.SUB_Get_Live_Assignments interview = run(student.Id, false);

        System.assertEquals(0, (Decimal) interview.getVariableValue('varN_AssignmentCount'), 'No assignments');
        System.assertEquals(null, interview.getVariableValue('varT_Assignments'), 'No classroom data returned');
        System.assert(((String) interview.getVariableValue('varT_Result')).startsWith('Not available'),
            'The agent should be told to verify first');
    }

    /* A verified student with no courses is told plainly that nothing is due. */
    @isTest
    static void studentWithNoCoursesIsToldNothingIsDue() {
        Contact student = makeStudent(new List<String>());
        Flow.Interview.SUB_Get_Live_Assignments interview = run(student.Id, true);

        System.assertEquals(0, (Decimal) interview.getVariableValue('varN_AssignmentCount'), 'No assignments');
        System.assert(((String) interview.getVariableValue('varT_Result')).startsWith('No upcoming'),
            'The result should say nothing is due');
    }
}

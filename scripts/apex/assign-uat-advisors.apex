/*****************************************************************
Name:          assign-uat-advisors.apex
============================================================
Purpose:       Makes the UAT advisors the assigned advisors of three demo
               students and creates one student with no advisor, so UAT
               can prove (SCA-5, SCA-14):
                 - UAT Advisor One sees only Avery Chen and Morgan Silva
                 - UAT Advisor Two sees only Riley Patel
                 - UAT Advisor Unassigned sees no students
                 - an alert for a student with no advisor goes to the
                   Advising Queue, with the exception logged
               The presenter stays Jordan Rivera's advisor, so the demo
               story is unchanged.

               Changing an advisor means updating BOTH the Advisee case
               team (role Advisor) and the student's account team (ADR-013).
               This script replaces whoever is the Advisor on those three
               students with the UAT advisor, on both teams.

               Run after setup-uat-users.apex. Re-run after any reload of
               load-demo-data.apex (the loader adds the presenter back).
               Safe to re-run. Deletes only team memberships, never records.
Usage:         sf apex run -f scripts/apex/assign-uat-advisors.apex -o <org>
============================================================
History
-------
VERSION  AUTHOR                 DATE        DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026  Created   SCA-5 UAT (fix WP-3)
*****************************************************************/
String USERNAME_SUFFIX = '@revecast.io.edupde';
String EMAIL_DOMAIN = 'student.jaxstate.example';
// student email -> UAT advisor username key
Map<String, String> advisorKeyByStudentEmail = new Map<String, String>{
    'avery.chen@' + EMAIL_DOMAIN   => 'sca.uat.advisor1',
    'morgan.silva@' + EMAIL_DOMAIN => 'sca.uat.advisor1',
    'riley.patel@' + EMAIL_DOMAIN  => 'sca.uat.advisor2'
};
String NO_ADVISOR_EMAIL = 'uat.noadvisor@uat.student.jaxstate.example'; // reserved domain
String NO_ADVISOR_ACCOUNT = 'UAT - No-Advisor Student Administrative Account';

// ---- Look-ups -----------------------------------------------------------------
Map<String, Id> userIdByKey = new Map<String, Id>();
for (User u : [SELECT Id, Username FROM User WHERE Username LIKE 'sca.uat.%' AND IsActive = true]) {
    userIdByKey.put(u.Username.removeEnd(USERNAME_SUFFIX), u.Id);
}
CaseTeamRole advisorRole = [SELECT Id FROM CaseTeamRole WHERE Name = 'Advisor' LIMIT 1];
Id adviseeRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
    .get('Advisee_Record').getRecordTypeId();
Map<Id, Contact> studentById = new Map<Id, Contact>(
    [SELECT Id, Email, AccountId FROM Contact WHERE Email IN :advisorKeyByStudentEmail.keySet()]);
Map<Id, Id> adviseeCaseByStudent = new Map<Id, Id>();
for (Case advisee : [SELECT Id, ContactId FROM Case WHERE RecordTypeId = :adviseeRecordType AND ContactId IN :studentById.keySet()]) {
    adviseeCaseByStudent.put(advisee.ContactId, advisee.Id);
}

// ---- Replace the Advisor on both teams --------------------------------------------
Set<Id> accountIds = new Set<Id>();
for (Contact s : studentById.values()) {
    accountIds.add(s.AccountId);
}
delete [SELECT Id FROM CaseTeamMember WHERE ParentId IN :adviseeCaseByStudent.values() AND TeamRoleId = :advisorRole.Id];
delete [SELECT Id FROM AccountTeamMember WHERE AccountId IN :accountIds AND TeamMemberRole = 'Advisor'];

List<CaseTeamMember> caseMembers = new List<CaseTeamMember>();
List<AccountTeamMember> accountMembers = new List<AccountTeamMember>();
for (Contact s : studentById.values()) {
    Id advisorId = userIdByKey.get(advisorKeyByStudentEmail.get(s.Email.toLowerCase()));
    caseMembers.add(new CaseTeamMember(ParentId = adviseeCaseByStudent.get(s.Id), MemberId = advisorId, TeamRoleId = advisorRole.Id));
    accountMembers.add(new AccountTeamMember(AccountId = s.AccountId, UserId = advisorId,
        TeamMemberRole = 'Advisor', AccountAccessLevel = 'Read',
        CaseAccessLevel = 'None', OpportunityAccessLevel = 'None'));
}
insert caseMembers;
insert accountMembers;

// ---- A student with no assigned advisor (Advising Queue path) ------------------------
List<Account> noAdvisorAccounts = [SELECT Id FROM Account WHERE Name = :NO_ADVISOR_ACCOUNT LIMIT 1];
Account noAdvisorAccount = noAdvisorAccounts.isEmpty()
    ? new Account(Name = NO_ADVISOR_ACCOUNT, Description = 'Fictional UAT student with no assigned advisor (SCA-14 queue path).')
    : noAdvisorAccounts[0];
upsert noAdvisorAccount;
List<Contact> noAdvisorStudents = [SELECT Id FROM Contact WHERE Email = :NO_ADVISOR_EMAIL LIMIT 1];
Contact noAdvisorStudent = noAdvisorStudents.isEmpty() ? new Contact(Email = NO_ADVISOR_EMAIL) : noAdvisorStudents[0];
noAdvisorStudent.FirstName = 'UAT';
noAdvisorStudent.LastName = 'No-Advisor Student';
noAdvisorStudent.AccountId = noAdvisorAccount.Id;
noAdvisorStudent.Title = 'First-year student';
noAdvisorStudent.Description = 'Fictional UAT student with no assigned advisor (SCA-14 queue path). Not enrolled, so the nightly scorer never scores it.';
upsert noAdvisorStudent;

System.debug('SCA-5 UAT advisors: ' + caseMembers.size() + ' case team and ' + accountMembers.size()
    + ' account team members set; no-advisor student ' + noAdvisorStudent.Id);

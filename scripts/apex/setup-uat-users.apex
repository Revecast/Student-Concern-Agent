/*****************************************************************
Name:          setup-uat-users.apex
============================================================
Purpose:       Creates the four non-admin UAT test users used to prove
               "advisors see only their own students" (SCA-5) and the
               crisis path (SCA-36), and puts the counselor in the
               Counseling Center queue as a PLACEHOLDER until the real
               crisis contacts are named (open answer 9).

               Users (Standard User profile, never System Administrator):
                 UAT Advisor One        - advisor for Avery Chen, Morgan Silva
                 UAT Advisor Two        - advisor for Riley Patel
                 UAT Advisor Unassigned - advisor with no students
                 UAT Counselor          - Counseling Center queue member

               Every user's email is UAT_EMAIL, so the password-setup
               emails go to the tester. No password is set or stored here.
               Safe to re-run: existing users are kept; missing licences,
               permission sets and queue membership are added.

               Run assign-uat-advisors.apex AFTER this script (setup and
               data DML can't share a transaction) and AFTER any reload of
               load-demo-data.apex.
Usage:         sf apex run -f scripts/apex/setup-uat-users.apex -o <org>
============================================================
History
-------
VERSION  AUTHOR                 DATE        DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026  Created   SCA-5 UAT (fix WP-3, WP-4)
*****************************************************************/
// ---- Settings -------------------------------------------------------------
String UAT_EMAIL = 'ernie.maldonado@revecast.io';     // receives password-setup emails
String USERNAME_SUFFIX = '@revecast.io.edupde';       // keeps usernames unique to this org
String TIME_ZONE = 'America/Los_Angeles';             // org time zone

// key, first name, last name, alias, is advisor (gets agent access)
List<List<Object>> uatUsers = new List<List<Object>>{
    new List<Object>{'sca.uat.advisor1',   'UAT Advisor', 'One',        'uatadv1', true},
    new List<Object>{'sca.uat.advisor2',   'UAT Advisor', 'Two',        'uatadv2', true},
    new List<Object>{'sca.uat.unassigned', 'UAT Advisor', 'Unassigned', 'uatadvu', true},
    new List<Object>{'sca.uat.counselor',  'UAT',         'Counselor',  'uatcoun', false}
};

// Permission sets for every UAT user, and the extra ones for advisors (agent use).
List<String> COMMON_PERMISSION_SETS = new List<String>{'EducationCloudAccess'};
List<String> ADVISOR_PERMISSION_SETS = new List<String>{'EinsteinGPTPromptTemplateUser', 'CopilotSalesforceUser'};
String ADVISOR_GROUP = 'Student_Success_Advisor';

// ---- Users ------------------------------------------------------------------
Profile standardUser = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
Set<String> usernames = new Set<String>();
for (List<Object> row : uatUsers) {
    usernames.add((String) row[0] + USERNAME_SUFFIX);
}
Map<String, User> userByUsername = new Map<String, User>();
for (User existing : [SELECT Id, Username, IsActive FROM User WHERE Username IN :usernames]) {
    userByUsername.put(existing.Username, existing);
}
List<User> newUsers = new List<User>();
for (List<Object> row : uatUsers) {
    String username = (String) row[0] + USERNAME_SUFFIX;
    if (!userByUsername.containsKey(username)) {
        newUsers.add(new User(
            Username = username, Email = UAT_EMAIL,
            FirstName = (String) row[1], LastName = (String) row[2], Alias = (String) row[3],
            ProfileId = standardUser.Id, TimeZoneSidKey = TIME_ZONE,
            LocaleSidKey = 'en_US', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8',
            Title = 'UAT test user - Student Concern Agent (not a real person)'));
    }
}
// Send the standard welcome email so the tester sets each password.
Database.DMLOptions emailOption = new Database.DMLOptions();
emailOption.EmailHeader.triggerUserEmail = true;
Database.insert(newUsers, emailOption);
for (User created : newUsers) {
    userByUsername.put(created.Username, created);
}

// ---- Permission set licences ----------------------------------------------------
// Assigning a licensed permission set needs the licence first.
Set<String> neededPermissionSets = new Set<String>(COMMON_PERMISSION_SETS);
neededPermissionSets.addAll(ADVISOR_PERMISSION_SETS);
Map<String, PermissionSet> permissionSetByName = new Map<String, PermissionSet>();
for (PermissionSet ps : [SELECT Id, Name, LicenseId FROM PermissionSet WHERE Name IN :neededPermissionSets]) {
    permissionSetByName.put(ps.Name, ps);
}
PermissionSetGroup advisorGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :ADVISOR_GROUP LIMIT 1];

Map<Id, Set<Id>> licencesByUser = new Map<Id, Set<Id>>();
Map<Id, Set<Id>> permissionSetsByUser = new Map<Id, Set<Id>>();
List<Id> userIds = new List<Id>();
for (User u : userByUsername.values()) {
    userIds.add(u.Id);
    licencesByUser.put(u.Id, new Set<Id>());
    permissionSetsByUser.put(u.Id, new Set<Id>());
}
for (PermissionSetLicenseAssign pla : [SELECT AssigneeId, PermissionSetLicenseId FROM PermissionSetLicenseAssign WHERE AssigneeId IN :userIds]) {
    licencesByUser.get(pla.AssigneeId).add(pla.PermissionSetLicenseId);
}
for (PermissionSetAssignment psa : [SELECT AssigneeId, PermissionSetId, PermissionSetGroupId FROM PermissionSetAssignment WHERE AssigneeId IN :userIds]) {
    permissionSetsByUser.get(psa.AssigneeId).add(psa.PermissionSetGroupId != null ? psa.PermissionSetGroupId : psa.PermissionSetId);
}

List<PermissionSetLicenseAssign> newLicences = new List<PermissionSetLicenseAssign>();
List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
for (List<Object> row : uatUsers) {
    User u = userByUsername.get((String) row[0] + USERNAME_SUFFIX);
    List<String> names = new List<String>(COMMON_PERMISSION_SETS);
    if ((Boolean) row[4]) {
        names.addAll(ADVISOR_PERMISSION_SETS);
    }
    for (String name : names) {
        PermissionSet ps = permissionSetByName.get(name);
        if (ps.LicenseId != null && !licencesByUser.get(u.Id).contains(ps.LicenseId)) {
            newLicences.add(new PermissionSetLicenseAssign(AssigneeId = u.Id, PermissionSetLicenseId = ps.LicenseId));
            licencesByUser.get(u.Id).add(ps.LicenseId);
        }
        if (!permissionSetsByUser.get(u.Id).contains(ps.Id)) {
            newAssignments.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id));
        }
    }
    // Every UAT user gets the advisor job function (read-only student data, the app).
    if (!permissionSetsByUser.get(u.Id).contains(advisorGroup.Id)) {
        newAssignments.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetGroupId = advisorGroup.Id));
    }
}
insert newLicences;
insert newAssignments;

// ---- Counseling Center queue (placeholder member, answer 9) -------------------
Group counselingCenter = [SELECT Id FROM Group WHERE DeveloperName = 'Counseling_Center' AND Type = 'Queue' LIMIT 1];
User counselor = userByUsername.get('sca.uat.counselor' + USERNAME_SUFFIX);
Integer inQueue = [SELECT COUNT() FROM GroupMember WHERE GroupId = :counselingCenter.Id AND UserOrGroupId = :counselor.Id];
if (inQueue == 0) {
    insert new GroupMember(GroupId = counselingCenter.Id, UserOrGroupId = counselor.Id);
}

System.debug('SCA-5 UAT users: ' + newUsers.size() + ' created, ' + newLicences.size() + ' licences, '
    + newAssignments.size() + ' permission assignments, counselor added to queue: ' + (inQueue == 0));

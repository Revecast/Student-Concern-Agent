/*****************************************************************
Name:          add-advising-queue-member.apex
============================================================
Purpose:       Adds one user to the Advising Queue (SCA-14), which
               receives the alert, task and notification when a student
               has no assigned advisor. Kept out of the queue metadata so
               no org-specific username is deployed. Safe to re-run: adds
               the member only if missing. Run separately from
               load-demo-data.apex (setup and data DML can't share a
               transaction).
Usage:         sf apex run -f scripts/apex/add-advising-queue-member.apex -o <org>
============================================================
History
-------
VERSION  AUTHOR                 DATE        DETAIL    DESCRIPTION
1.0      Revecast Orchestrate   19/11/2026  Created   SCA-14
*****************************************************************/
// Username of the person who works the Advising Queue. Default: the demo presenter.
String QUEUE_MEMBER_USERNAME = 'sean.speer@jaxconsult.com.edudemopde';

Group advisingQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Advising_Queue' AND Type = 'Queue' LIMIT 1];
User member = [SELECT Id FROM User WHERE Username = :QUEUE_MEMBER_USERNAME AND IsActive = true LIMIT 1];
Integer existing = [SELECT COUNT() FROM GroupMember WHERE GroupId = :advisingQueue.Id AND UserOrGroupId = :member.Id];
if (existing == 0) {
    insert new GroupMember(GroupId = advisingQueue.Id, UserOrGroupId = member.Id);
}
System.debug('QUEUE_MEMBERS ' + [SELECT COUNT() FROM GroupMember WHERE GroupId = :advisingQueue.Id]
    + ' (added: ' + (existing == 0) + ')');

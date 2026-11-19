"""SCA-36: messaging action with NO recipient input (NEVER rule, ADR-001).
Writes SUB_Send_Student_Message and the Counseling_Center queue."""
from flowgen import Flow
from mdgen import write

desc = ("Sends a message for the Student Concern Agent (SCA-36). Has NO recipient or address input: the caller picks a "
        "role and the flow resolves the address itself. Student: the student's own email. Assigned Advisor: the Advisor on "
        "the student's Advisee Record case team; with none, a Task to the Advising Queue (exception logged). Counseling "
        "Center: only when Is Crisis is true, as an urgent Task to the Counseling Center queue (Crisis exception logged). "
        "Any other role is refused. Every send, skip and failure writes an outreach log row (SCA-37). "
        "Update Message: v1 first version (SCA-36).")
f = Flow("SUB_Send_Student_Message", "SUB – Send Student Message", desc)
f.run_mode = "SystemModeWithoutSharing"
f.plain_start("Get_Student")

f.var("varT_StudentId", "String", "Id of the student (Contact) the message is about. The only person input; no address input exists.", is_input=True)
f.var("varP_RecipientRole", "String", "Who receives it: Student, Assigned Advisor or Counseling Center. Anything else is refused.", is_input=True)
f.var("varT_Subject", "String", "Message subject.", is_input=True)
f.var("varT_Body", "String", "Message body (plain text).", is_input=True)
f.var("varB_IsCrisis", "Boolean", "True only on the crisis path; required for the Counseling Center.", is_input=True, default=("bool", False))
f.var("varB_Sent", "Boolean", "True when the message was sent or handed to a queue.", is_output=True, default=("bool", False))
f.var("varT_Result", "String", "Plain result for the agent to relay.", is_output=True)
f.var("varP_RecipientType", "String", "Outreach log Recipient Type.", default=("str", "Student"))
f.var("varP_ExceptionUsed", "String", "Outreach log Exception Used.", default=("str", "None"))
f.var("varP_Channel", "String", "Outreach log Channel.", default=("str", "Email"))
f.var("varT_AdvisorUserId", "String", "Assigned advisor's User Id when known.")

f.formula("forT_CaseId", "String", "{!Get_Advisee_Case.Id}", "Advisee case Id, blank if none.")
f.formula("forB_HasAdvisor", "Boolean",
          'AND(NOT(ISBLANK({!Get_Assigned_Advisor.MemberId})), LEFT({!Get_Assigned_Advisor.MemberId}, 3) = "005")',
          "True when the Advisee case team has an Advisor who is a user.")
f.formula("forT_TaskSubject", "String", 'LEFT({!varT_Subject}, 255)', "Task subject, trimmed to 255 characters.")
f.formula("forT_FailureReason", "String", 'LEFT("Message not sent: " & {!$Flow.FaultMessage}, 255)', "Failure text for fault paths.")
f.formula("forD_Today", "Date", "{!$Flow.CurrentDate}", "Due date for queue tasks.")

FAULT = "Create_Failed_Log"
LOG = [("Student__c", ("ref", "Get_Student.Id")), ("Recipient_Type__c", ("ref", "varP_RecipientType")),
       ("Recipient_User__c", ("ref", "varT_AdvisorUserId")), ("Exception_Used__c", ("ref", "varP_ExceptionUsed")),
       ("Channel__c", ("ref", "varP_Channel")), ("Trigger_Score__c", ("ref", "Get_Student.Risk_Score__c")),
       ("Sent_At__c", ("ref", "$Flow.CurrentDateTime"))]

f.lookup("Get_Student", "Get Student", "Contact", [("Id", "EqualTo", ("ref", "varT_StudentId"))],
         "The student the message is about.", "Was_the_Student_Found")
f.decision("Was_the_Student_Found", "Was the Student Found?",
           [("Found", "Found", [("Get_Student.Id", "IsNull", ("bool", False))], "Which_Recipient")],
           "Refuse_Unknown_Student", "Stops when the Id is not a contact.", default_label="Not Found")
f.assign("Refuse_Unknown_Student", "Refuse Unknown Student",
         [("varT_Result", "Assign", ("str", "Not sent: the student could not be found."))], None, "Nothing to send to.")

f.decision("Which_Recipient", "Which Recipient?",
           [("Role_Student", "Student", [("varP_RecipientRole", "EqualTo", ("str", "Student"))], "Does_the_Student_Have_an_Email"),
            ("Role_Advisor", "Assigned Advisor", [("varP_RecipientRole", "EqualTo", ("str", "Assigned Advisor"))], "Set_Advisor_Log_Values"),
            ("Role_Counseling_Crisis", "Counseling Center on Crisis",
             [("varP_RecipientRole", "EqualTo", ("str", "Counseling Center")), ("varB_IsCrisis", "EqualTo", ("bool", True))],
             "Set_Counseling_Log_Values")],
           "Refuse_Recipient", "The NEVER rule: only the student, the assigned advisor, or the counseling center on a crisis.",
           default_label="Anyone Else")
f.assign("Refuse_Recipient", "Refuse Recipient",
         [("varT_Result", "Assign", ("str", "Not sent: I can only message the student or their assigned advisor. "
                                           "The counseling center is contacted only in a crisis."))],
         None, "Refusal for any other recipient (professor, parent, friend) or counseling without a crisis.")

# --- student
f.decision("Does_the_Student_Have_an_Email", "Does the Student Have an Email?",
           [("Has_Email", "Has Email", [("Get_Student.Email", "IsNull", ("bool", False))], "Email_the_Student")],
           "Create_No_Email_Log", "Skips and logs when the student record has no email.", default_label="No Email")
f.action("Email_the_Student", "Email the Student", "emailSimple", "emailSimple",
         [("emailAddresses", ("ref", "Get_Student.Email")), ("emailSubject", ("ref", "varT_Subject")),
          ("emailBody", ("ref", "varT_Body")), ("recipientId", ("ref", "Get_Student.Id")),
          ("logEmailOnSend", ("bool", True))],
         "Sends only to the email on the student's own record.", "Create_Sent_Log", fault=FAULT)
f.create("Create_No_Email_Log", "Create No Email Log", "Student_Outreach__c",
         LOG + [("Status__c", ("str", "Skipped")), ("Failure_Reason__c", ("str", "No email on the student record."))],
         "Outreach log: skipped, no email.", "Set_No_Email_Result", fault=FAULT)
f.assign("Set_No_Email_Result", "Set No Email Result",
         [("varT_Result", "Assign", ("str", "Not sent: the student has no email on their record."))], None, "Result for the agent.")

# --- advisor
f.assign("Set_Advisor_Log_Values", "Set Advisor Log Values",
         [("varP_RecipientType", "Assign", ("str", "Assigned Advisor"))], "Get_Advisee_Record_Type", "Log values for the advisor path.")
f.lookup("Get_Advisee_Record_Type", "Get Advisee Record Type", "RecordType",
         [("SobjectType", "EqualTo", ("str", "Case")), ("DeveloperName", "EqualTo", ("str", "Advisee_Record"))],
         "Advisee Record case type.", "Get_Advisee_Case", fault=FAULT)
f.lookup("Get_Advisee_Case", "Get Advisee Case", "Case",
         [("ContactId", "EqualTo", ("ref", "Get_Student.Id")), ("RecordTypeId", "EqualTo", ("ref", "Get_Advisee_Record_Type.Id"))],
         "The student's Advisee Record.", "Get_Advisor_Team_Role", fault=FAULT)
f.lookup("Get_Advisor_Team_Role", "Get Advisor Team Role", "CaseTeamRole", [("Name", "EqualTo", ("str", "Advisor"))],
         "Advisor case team role.", "Get_Assigned_Advisor", fault=FAULT)
f.lookup("Get_Assigned_Advisor", "Get Assigned Advisor", "CaseTeamMember",
         [("ParentId", "EqualTo", ("ref", "forT_CaseId")), ("TeamRoleId", "EqualTo", ("ref", "Get_Advisor_Team_Role.Id"))],
         "The assigned advisor.", "Does_the_Student_Have_an_Advisor", fault=FAULT, sort=("CreatedDate", "Asc"))
f.decision("Does_the_Student_Have_an_Advisor", "Does the Student Have an Advisor?",
           [("Has_Advisor", "Has Advisor", [("forB_HasAdvisor", "EqualTo", ("bool", True))], "Get_Advisor_User")],
           "Set_Queue_Log_Values", "Assigned advisor, or the Advising Queue exception.", default_label="No Advisor")
f.lookup("Get_Advisor_User", "Get Advisor User", "User", [("Id", "EqualTo", ("ref", "Get_Assigned_Advisor.MemberId"))],
         "The advisor's user record, for their email.", "Email_the_Advisor", fault=FAULT)
f.action("Email_the_Advisor", "Email the Advisor", "emailSimple", "emailSimple",
         [("emailAddresses", ("ref", "Get_Advisor_User.Email")), ("emailSubject", ("ref", "varT_Subject")),
          ("emailBody", ("ref", "varT_Body")), ("logEmailOnSend", ("bool", True))],
         "Sends only to the assigned advisor's own user email.", "Set_Advisor_User", fault=FAULT)
f.assign("Set_Advisor_User", "Set Advisor User",
         [("varT_AdvisorUserId", "Assign", ("ref", "Get_Advisor_User.Id"))], "Create_Sent_Log", "Records who received it.")
f.assign("Set_Queue_Log_Values", "Set Queue Log Values",
         [("varP_RecipientType", "Assign", ("str", "Advising Queue")), ("varP_ExceptionUsed", "Assign", ("str", "Advising Queue")),
          ("varP_Channel", "Assign", ("str", "Task"))], "Get_Advising_Queue", "Advising Queue exception (ADR-001).")
f.lookup("Get_Advising_Queue", "Get Advising Queue", "Group",
         [("DeveloperName", "EqualTo", ("str", "Advising_Queue")), ("Type", "EqualTo", ("str", "Queue"))],
         "Fallback when there is no assigned advisor.", "Create_Advising_Queue_Task", fault=FAULT)
f.create("Create_Advising_Queue_Task", "Create Advising Queue Task", "Task",
         [("OwnerId", ("ref", "Get_Advising_Queue.Id")), ("WhoId", ("ref", "Get_Student.Id")),
          ("Subject", ("ref", "forT_TaskSubject")), ("Description", ("ref", "varT_Body")),
          ("ActivityDate", ("ref", "forD_Today")), ("Priority", ("str", "Normal")), ("Status", ("str", "Not Started"))],
         "The message as a task for the Advising Queue.", "Create_Sent_Log", fault=FAULT)

# --- counseling (crisis only)
f.assign("Set_Counseling_Log_Values", "Set Counseling Log Values",
         [("varP_RecipientType", "Assign", ("str", "Counseling Center")), ("varP_ExceptionUsed", "Assign", ("str", "Crisis")),
          ("varP_Channel", "Assign", ("str", "Task"))], "Get_Counseling_Queue", "Crisis exception (ADR-001).")
f.lookup("Get_Counseling_Queue", "Get Counseling Queue", "Group",
         [("DeveloperName", "EqualTo", ("str", "Counseling_Center")), ("Type", "EqualTo", ("str", "Queue"))],
         "The counseling center queue.", "Create_Counseling_Task", fault=FAULT)
f.create("Create_Counseling_Task", "Create Counseling Task", "Task",
         [("OwnerId", ("ref", "Get_Counseling_Queue.Id")), ("WhoId", ("ref", "Get_Student.Id")),
          ("Subject", ("ref", "forT_TaskSubject")), ("Description", ("ref", "varT_Body")),
          ("ActivityDate", ("ref", "forD_Today")), ("Priority", ("str", "High")), ("Status", ("str", "Not Started"))],
         "Urgent task for the counseling center, due today.", "Create_Sent_Log", fault=FAULT)

# --- shared ends
f.create("Create_Sent_Log", "Create Sent Log", "Student_Outreach__c", LOG + [("Status__c", ("str", "Sent"))],
         "Outreach log: sent.", "Set_Sent_Result", fault=FAULT)
f.assign("Set_Sent_Result", "Set Sent Result",
         [("varB_Sent", "Assign", ("bool", True)), ("varT_Result", "Assign", ("str", "Sent."))], None, "Result for the agent.")
f.create(FAULT, "Create Failed Log", "Student_Outreach__c",
         LOG + [("Status__c", ("str", "Failed")), ("Failure_Reason__c", ("ref", "forT_FailureReason"))],
         "Fault path: logs the failure.", "Set_Failed_Result")
f.assign("Set_Failed_Result", "Set Failed Result",
         [("varT_Result", "Assign", ("str", "Not sent: something went wrong. The failure has been logged."))], None, "Result for the agent.")
f.save()

write("queues/Counseling_Center.queue-meta.xml", """<Queue xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Counseling_Center</fullName>
    <doesSendEmailToMembers>false</doesSendEmailToMembers>
    <name>Counseling Center</name>
    <queueSobject><sobjectType>Task</sobjectType></queueSobject>
</Queue>""")
print("ok")

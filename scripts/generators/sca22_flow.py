"""SCA-22: SUB_Find_My_Student — gate for the advisor agent. Returns a student only when the running user is the
Advisor on that student's Advisee Record case team. No queries inside loops."""
from flowgen import Flow

f = Flow("SUB_Find_My_Student", "SUB – Find My Student",
         "Gate for the advisor agent (SCA-22, SCA-23). Finds a student by full name and returns the student Id ONLY when the "
         "running user is the Advisor on that student's Advisee Record case team. Otherwise returns a generic 'not on your "
         "caseload' result that does not confirm whether the student exists. Queries run once each, outside loops. "
         "Update Message: v1 first version (SCA-22).")
f.run_mode = "SystemModeWithoutSharing"
f.plain_start("Get_Students_By_Name")
f.var("varT_StudentName", "String", "Student's full name as the advisor typed it.", is_input=True)
f.var("varT_StudentId", "String", "The student's Contact Id when exactly one assigned student matches; blank otherwise.", is_output=True)
f.var("varB_IsAssigned", "Boolean", "True only when exactly one matching student is assigned to the running user.", is_output=True,
      default=("bool", False))
f.var("varT_Result", "String", "Plain result for the agent.", is_output=True)
f.var("varT_ContactIds", "String", "Ids of contacts with that name.", collection=True)
f.var("varT_CaseIds", "String", "Ids of those contacts' Advisee Record cases.", collection=True)
f.var("varN_Matches", "Number", "Assigned students found.", default=("num", 0), scale=0)
f.var("varT_MatchedCaseId", "String", "Advisee case of the single match.")

f.lookup("Get_Students_By_Name", "Get Students By Name", "Contact", [("Name", "EqualTo", ("ref", "varT_StudentName"))],
         "Contacts with exactly that full name.", "Loop_Through_Students", first=False)
f.loop("Loop_Through_Students", "Loop Through Students", "Get_Students_By_Name", "Collect_Student_Id", "Any_Students_Found",
       "Collects the Ids for one query.")
f.assign("Collect_Student_Id", "Collect Student Id", [("varT_ContactIds", "Add", ("ref", "Loop_Through_Students.Id"))],
         "Loop_Through_Students", "Adds the Id.")
f.decision("Any_Students_Found", "Any Students Found?",
           [("Students_Found", "Found", [("varT_ContactIds", "IsEmpty", ("bool", False))], "Get_Advisee_Record_Type")],
           "Set_Not_Assigned", "No contact has that name.", default_label="None")
f.lookup("Get_Advisee_Record_Type", "Get Advisee Record Type", "RecordType",
         [("SobjectType", "EqualTo", ("str", "Case")), ("DeveloperName", "EqualTo", ("str", "Advisee_Record"))],
         "Advisee Record case type.", "Get_Advisor_Team_Role")
f.lookup("Get_Advisor_Team_Role", "Get Advisor Team Role", "CaseTeamRole", [("Name", "EqualTo", ("str", "Advisor"))],
         "Advisor case team role.", "Get_Advisee_Cases")
f.lookup("Get_Advisee_Cases", "Get Advisee Cases", "Case",
         [("ContactId", "In", ("ref", "varT_ContactIds")), ("RecordTypeId", "EqualTo", ("ref", "Get_Advisee_Record_Type.Id"))],
         "Advisee Records of the matching contacts.", "Loop_Through_Cases", first=False)
f.loop("Loop_Through_Cases", "Loop Through Cases", "Get_Advisee_Cases", "Collect_Case_Id", "Any_Cases_Found",
       "Collects case Ids for one query.")
f.assign("Collect_Case_Id", "Collect Case Id", [("varT_CaseIds", "Add", ("ref", "Loop_Through_Cases.Id"))],
         "Loop_Through_Cases", "Adds the Id.")
f.decision("Any_Cases_Found", "Any Cases Found?",
           [("Cases_Found", "Found", [("varT_CaseIds", "IsEmpty", ("bool", False))], "Get_My_Advisor_Memberships")],
           "Set_Not_Assigned", "No Advisee Record for those contacts.", default_label="None")
f.lookup("Get_My_Advisor_Memberships", "Get My Advisor Memberships", "CaseTeamMember",
         [("ParentId", "In", ("ref", "varT_CaseIds")), ("MemberId", "EqualTo", ("ref", "$User.Id")),
          ("TeamRoleId", "EqualTo", ("ref", "Get_Advisor_Team_Role.Id"))],
         "Where the running user is the Advisor on those cases.", "Loop_Through_Memberships", first=False)
f.loop("Loop_Through_Memberships", "Loop Through Memberships", "Get_My_Advisor_Memberships", "Count_Match", "Find_Matched_Case",
       "Counts assigned matches.")
f.assign("Count_Match", "Count Match",
         [("varN_Matches", "Add", ("num", 1)), ("varT_MatchedCaseId", "Assign", ("ref", "Loop_Through_Memberships.ParentId"))],
         "Loop_Through_Memberships", "One more assigned student.")
f.loop("Find_Matched_Case", "Find Matched Case", "Get_Advisee_Cases", "Is_This_the_Matched_Case", "How_Many_Matches",
       "Finds the contact behind the matched case.")
f.decision("Is_This_the_Matched_Case", "Is This the Matched Case?",
           [("Matched", "Matched", [("Find_Matched_Case.Id", "EqualTo", ("ref", "varT_MatchedCaseId"))], "Set_Candidate_Student")],
           "Find_Matched_Case", "Compares case Ids.", default_label="Other Case")
f.assign("Set_Candidate_Student", "Set Candidate Student",
         [("varT_StudentId", "Assign", ("ref", "Find_Matched_Case.ContactId"))], "Find_Matched_Case", "The student behind the match.")
f.decision("How_Many_Matches", "How Many Matches?",
           [("Exactly_One", "Exactly One", [("varN_Matches", "EqualTo", ("num", 1))], "Set_Assigned"),
            ("Several", "Several", [("varN_Matches", "GreaterThan", ("num", 1))], "Set_Several")],
           "Set_Not_Assigned", "Only one assigned student may be returned.", default_label="None")
f.assign("Set_Assigned", "Set Assigned",
         [("varB_IsAssigned", "Assign", ("bool", True)), ("varT_Result", "Assign", ("str", "OK"))], None, "Gate passes.")
f.assign("Set_Several", "Set Several",
         [("varT_StudentId", "Assign", ("str", "")),
          ("varT_Result", "Assign", ("str", "More than one of your students has that name. Ask the advisor for more detail."))],
         None, "Ambiguous: return nothing.")
f.assign("Set_Not_Assigned", "Set Not Assigned",
         [("varT_StudentId", "Assign", ("str", "")),
          ("varT_Result", "Assign", ("str", "That student is not on your caseload. I can only help with students assigned to you."))],
         None, "Gate fails; does not confirm whether the student exists.")
f.save()
print("ok")

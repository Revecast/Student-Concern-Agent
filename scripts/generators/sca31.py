"""SCA-31: simulated get_live_assignments(student) behind a fixed interface (ADR-004)."""
import re
from flowgen import Flow
from mdgen import write, field, esc, ROOT

OBJ = "Simulated_Assignment__mdt"
write(f"objects/{OBJ}/{OBJ}.object-meta.xml", """<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
  <description>Sample upcoming assignments for the simulated classroom system (ADR-004), matched to a student's courses by course code. Read by SUB – LMS – Simulated Assignments. A real LMS replaces that subflow, not this data. SCA-31.</description>
  <label>Simulated Assignment</label>
  <pluralLabel>Simulated Assignments</pluralLabel>
  <visibility>Public</visibility>
</CustomObject>""")
field(OBJ, "Course_Code__c", "Course Code", "Text",
      "Course code the assignment belongs to (for example BIO 101). Matched against the start of Classroom Activity Course Name.",
      "Course code, for example BIO 101.", length=20, required=True)
field(OBJ, "Assignment_Title__c", "Assignment Title", "Text", "Assignment title as the classroom system would show it.",
      "Assignment title.", length=120, required=True)
field(OBJ, "Assignment_Type__c", "Assignment Type", "Text", "Kind of work, for example lab report, quiz, essay.",
      "Kind of work.", length=40, required=True)
field(OBJ, "Due_In_Days__c", "Due In Days", "Number", "Days from today the assignment is due, so the demo always shows upcoming work.",
      "Days from today the assignment is due.", precision=3, scale=0, required=True)
field(OBJ, "Points__c", "Points", "Number", "Points the assignment is worth.", "Points the assignment is worth.",
      precision=4, scale=0, required=True)

SAMPLES = [
    ("BIO_101_Lab_Report_4", "BIO 101", "Lab report 4: Cellular respiration", "lab report", 3, 20),
    ("BIO_101_Chapter_9_Quiz", "BIO 101", "Chapter 9 quiz", "quiz", 6, 10),
    ("ENG_101_Essay_2_Draft", "ENG 101", "Essay 2 draft: Making an argument", "essay", 4, 50),
    ("ENG_101_Peer_Review", "ENG 101", "Peer review of two classmates' drafts", "discussion", 8, 15),
    ("MATH_110_Problem_Set_7", "MATH 110", "Problem set 7: Quadratic equations", "problem set", 2, 25),
    ("MATH_110_Practice_Exam", "MATH 110", "Practice exam for midterm 2", "practice exam", 9, 10),
]
for dev, code, title, kind, days, pts in SAMPLES:
    write(f"customMetadata/Simulated_Assignment.{dev}.md-meta.xml", f"""<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>{esc(code + ' ' + title)[:40]}</label>
    <protected>false</protected>
    <values><field>Assignment_Title__c</field><value xsi:type="xsd:string">{esc(title)}</value></values>
    <values><field>Assignment_Type__c</field><value xsi:type="xsd:string">{esc(kind)}</value></values>
    <values><field>Course_Code__c</field><value xsi:type="xsd:string">{code}</value></values>
    <values><field>Due_In_Days__c</field><value xsi:type="xsd:double">{days}</value></values>
    <values><field>Points__c</field><value xsi:type="xsd:double">{pts}</value></values>
</CustomMetadata>""")

items = "".join(f"<layoutItems><behavior>Required</behavior><field>{f}</field></layoutItems>"
                for f in ("Course_Code__c", "Assignment_Title__c", "Assignment_Type__c", "Due_In_Days__c", "Points__c"))
write(f"layouts/{OBJ}-Simulated Assignment Layout.layout-meta.xml", f"""<Layout xmlns="http://soap.sforce.com/2006/04/metadata"><layoutSections><customLabel>true</customLabel><detailHeading>true</detailHeading><editHeading>true</editHeading><label>Information</label><layoutColumns><layoutItems><behavior>Required</behavior><field>MasterLabel</field></layoutItems><layoutItems><behavior>Required</behavior><field>DeveloperName</field></layoutItems></layoutColumns><layoutColumns><layoutItems><behavior>Readonly</behavior><field>NamespacePrefix</field></layoutItems><layoutItems><behavior>Edit</behavior><field>IsProtected</field></layoutItems></layoutColumns><style>TwoColumnsTopToBottom</style></layoutSections><layoutSections><customLabel>true</customLabel><detailHeading>true</detailHeading><editHeading>true</editHeading><label>Assignment</label><layoutColumns>{items}</layoutColumns><style>OneColumn</style></layoutSections><showEmailCheckbox>false</showEmailCheckbox><showHighlightsPanel>false</showHighlightsPanel><showInteractionLogPanel>false</showInteractionLogPanel><showRunAssignmentRulesCheckbox>false</showRunAssignmentRulesCheckbox><showSubmitAndAttachButton>false</showSubmitAndAttachButton></Layout>""")

write("permissionsets/SYS_Simulated_LMS_Read.permissionset-meta.xml", """<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
  <label>SYS – Simulated LMS Read</label>
  <description>Read access to the Simulated Assignment custom metadata (sample upcoming assignments for the simulated classroom system, ADR-004) for the agent's running user and admins. SCA-31.</description>
  <hasActivationRequired>false</hasActivationRequired>
  <customMetadataTypeAccesses><enabled>true</enabled><name>Simulated_Assignment__mdt</name></customMetadataTypeAccesses>
</PermissionSet>""")
for grp in ("Student_Concern_Agent_User", "Student_Concern_Administrator"):
    p = f"{ROOT}/permissionsetgroups/{grp}.permissionsetgroup-meta.xml"
    x = open(p).read()
    if "SYS_Simulated_LMS_Read" not in x:
        x = re.sub(r"(</permissionSets>)(?!.*</permissionSets>)", r"\1<permissionSets>SYS_Simulated_LMS_Read</permissionSets>", x, count=1, flags=re.S)
        open(p, "w").write(x)

# ---------------------------------------------------------------- implementation (swappable)
impl = Flow("SUB_LMS_Simulated_Assignments", "SUB – LMS – Simulated Assignments",
            "Simulated classroom system (ADR-004): returns a student's upcoming assignments by matching their Classroom Activity "
            "courses to Simulated Assignment sample data. Same inputs and outputs as the interface SUB – Get Live Assignments, so a "
            "real Canvas or Moodle subflow can replace this one without changing the agent. Update Message: v1 first version (SCA-31).")
impl.run_mode = "SystemModeWithoutSharing"
impl.plain_start("Get_Classroom_Activities")
impl.var("varT_StudentId", "String", "The student (Contact) Id.", is_input=True)
impl.var("varT_Assignments", "String", "Assignments, one sentence each, separated by '; '.", is_output=True, default=("str", ""))
impl.var("varN_AssignmentCount", "Number", "How many assignments were returned.", is_output=True, default=("num", 0), scale=0)
impl.formula("forD_DueDate", "Date", "{!$Flow.CurrentDate} + {!Loop_Assignments.Due_In_Days__c}", "Due date of the current sample.")
impl.formula("forT_Line", "String",
             'IF({!varN_AssignmentCount} > 1, "; ", "") & {!Loop_Courses.Course_Name__c} & ": " & {!Loop_Assignments.Assignment_Title__c} & " (" & '
             '{!Loop_Assignments.Assignment_Type__c} & "), due " & TEXT({!forD_DueDate}) & ", " & '
             'TEXT({!Loop_Assignments.Points__c}) & " points"',
             "One assignment in the fixed interface shape: Course: Title (type), due YYYY-MM-DD, N points. Counted before it is added, so later lines start with a separator.")
impl.formula("forB_Matches", "Boolean",
             'BEGINS({!Loop_Courses.Course_Name__c}, {!Loop_Assignments.Course_Code__c})',
             "True when the sample belongs to the current course.")
impl.lookup("Get_Classroom_Activities", "Get Classroom Activities", "Classroom_Activity__c",
            [("Student__c", "EqualTo", ("ref", "varT_StudentId"))], "The student's courses.", "Get_Simulated_Assignments",
            first=False, sort=("Course_Name__c", "Asc"))
impl.lookup("Get_Simulated_Assignments", "Get Simulated Assignments", OBJ,
            [("Course_Code__c", "IsNull", ("bool", False))], "All sample assignments.", "Loop_Courses",
            first=False, sort=("Due_In_Days__c", "Asc"))
impl.loop("Loop_Courses", "Loop Through Courses", "Get_Classroom_Activities", "Loop_Assignments", None, "Each course.")
impl.loop("Loop_Assignments", "Loop Through Assignments", "Get_Simulated_Assignments", "Is_It_This_Course", "Loop_Courses",
          "Each sample assignment.")
impl.decision("Is_It_This_Course", "Is It This Course?",
              [("Same_Course", "Same Course", [("forB_Matches", "EqualTo", ("bool", True))], "Add_Assignment")],
              "Loop_Assignments", "Keeps samples for this course only.", default_label="Other Course")
impl.assign("Add_Assignment", "Add Assignment",
            [("varN_AssignmentCount", "Add", ("num", 1)), ("varT_Assignments", "Add", ("ref", "forT_Line"))],
            "Loop_Assignments", "Appends the assignment and counts it.")
impl.save()

# ---------------------------------------------------------------- interface (what the agent calls)
f = Flow("SUB_Get_Live_Assignments", "SUB – Get Live Assignments",
         "get_live_assignments(student) for the student agent (SCA-31). Fixed interface: inputs student Id and Is Verified; "
         "outputs Assignments, Assignment Count and Result. Refuses unless the student is verified (FERPA, SCA-34). Calls the "
         "classroom-system implementation subflow, today SUB – LMS – Simulated Assignments; a real LMS swaps only that subflow. "
         "Update Message: v1 first version (SCA-31).")
f.run_mode = "SystemModeWithoutSharing"
f.plain_start("Is_the_Student_Verified")
f.var("varT_StudentId", "String", "The student (Contact) Id.", is_input=True)
f.var("varB_IsVerified", "Boolean", "True only when the student's identity is verified (portal login or one-time code).",
      is_input=True, default=("bool", False))
f.var("varT_Assignments", "String", "Upcoming assignments, one sentence each, separated by '; '. Blank when refused.", is_output=True)
f.var("varN_AssignmentCount", "Number", "How many assignments were returned.", is_output=True, default=("num", 0), scale=0)
f.var("varT_Result", "String", "Plain result for the agent.", is_output=True)
f.decision("Is_the_Student_Verified", "Is the Student Verified?",
           [("Verified", "Verified", [("varB_IsVerified", "EqualTo", ("bool", True))], "Get_Assignments_From_Classroom_System")],
           "Refuse_Unverified", "FERPA: assignments only for a verified student.", default_label="Not Verified")
f.assign("Refuse_Unverified", "Refuse Unverified",
         [("varT_Result", "Assign", ("str", "Not available: the student must verify their identity first."))], None,
         "No classroom data is read.")
f.subflow("Get_Assignments_From_Classroom_System", "Get Assignments From Classroom System", "SUB_LMS_Simulated_Assignments",
          [("varT_StudentId", ("ref", "varT_StudentId"))],
          "The swappable classroom-system implementation.", "Were_Assignments_Found",
          outputs=[("varT_Assignments", "varT_Assignments"), ("varN_AssignmentCount", "varN_AssignmentCount")])
f.decision("Were_Assignments_Found", "Were Assignments Found?",
           [("Found", "Found", [("varN_AssignmentCount", "GreaterThan", ("num", 0))], "Set_Found_Result")],
           "Set_None_Result", "Says plainly when there is nothing due.", default_label="None")
f.assign("Set_Found_Result", "Set Found Result", [("varT_Result", "Assign", ("str", "OK"))], None, "Assignments returned.")
f.assign("Set_None_Result", "Set None Result",
         [("varT_Result", "Assign", ("str", "No upcoming assignments found in the classroom system."))], None, "Nothing due.")
f.save()
print("ok")

# Simulated classroom system (LMS) — feed interface (SCA-7, ADR-004)

The demo has no real Canvas or Moodle. Classroom activity is stored in **Classroom Activity**
(`Classroom_Activity__c`), one record per student and course, loaded by the demo data script (SCA-8).
A real integration later replaces only the loader: it upserts the same fields by `External_Key__c`,
and the nightly scorer (SCA-9) does not change.

| Field | Type | Real-feed source | Notes |
|---|---|---|---|
| `Student__c` | Master-detail → Contact | LMS user mapped to the student Contact | Access follows the student record |
| `External_Key__c` | Text(120), unique external ID | `<student key>\|<course key>` | Upsert key; duplicates are rejected |
| `Course_Offering__c` | Lookup → CourseOffering | LMS course mapped to the section | Optional |
| `Course_Name__c` | Text(120) | LMS course title | Used in the plain-language risk reason |
| `Last_Login__c` | DateTime | Last course access / login | Drives no-login points |
| `Current_Grade__c` | Number 0–100 | Current course score | Below 70 = below C |
| `Grade_Two_Weeks_Ago__c` | Number 0–100 | Score snapshot 14 days ago | A drop of one letter band = 2 points |
| `Source_System__c` | Picklist | Simulated / Canvas / Moodle / Blackboard / D2L Brightspace | |

Upsert example (any loader): `sf data upsert bulk -s Classroom_Activity__c -i External_Key__c -f activity.csv`.

## get_live_assignments(student) — SCA-31

The agent calls **SUB – Get Live Assignments** (`SUB_Get_Live_Assignments`). That flow is the fixed
interface; it never changes when a real LMS arrives.

| | Name | Type | Meaning |
|---|---|---|---|
| In | `varT_StudentId` | Text | The student (Contact) Id |
| In | `varB_IsVerified` | Boolean | True only after portal login or a one-time code (SCA-34). Default false |
| Out | `varT_Assignments` | Text | One entry per assignment, separated by `; `, each `Course: Title (type), due YYYY-MM-DD, N points`. Blank when refused |
| Out | `varN_AssignmentCount` | Number | How many entries |
| Out | `varT_Result` | Text | `OK`, `No upcoming assignments found in the classroom system.`, or `Not available: the student must verify their identity first.` |

When the student is not verified, the interface stops before reading any classroom data (FERPA).

**Implementation behind it:** the subflow **SUB – LMS – Simulated Assignments**
(`SUB_LMS_Simulated_Assignments`), with the same student input and assignment outputs. It reads the
student's Classroom Activity courses and returns the matching **Simulated Assignment** custom metadata
samples (2 each for BIO 101, ENG 101, MATH 110), matched where the course name begins with the course code.
Due dates are "days from today", so the demo always shows upcoming work. Sorted by course, soonest first.

**Swapping in a real Canvas or Moodle:** build a subflow with the same inputs and outputs that calls the
LMS (Named Credential + HTTP callout), and change the one subflow element
*Get Assignments From Classroom System* in the interface to point at it. The agent and its actions do not change.

Tested 2026-11-19: `StudentLiveAssignmentsTest` (3 tests: own courses only and exact shape, unverified
refused, no courses). Live for Jordan Rivera: verified → 6 assignments across his 3 courses; unverified → none.

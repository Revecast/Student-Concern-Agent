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

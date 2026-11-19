# Configuration — risk score settings (SCA-10)

The nightly risk score reads every weight and limit from the custom metadata type
**Risk Score Setting** (`Risk_Score_Setting__mdt`), record **Default**. Change a value in
Setup → Custom Metadata Types → Risk Score Setting → Manage Records → Default, and the next
scoring run uses it. No deploy needed.

| Field | Default | Meaning |
|---|---|---|
| Missed Class Points | 2 | Points per class marked Absent in the window |
| Missed Class Max Points | 6 | Cap on missed-class points |
| Missed Class Window Days | 14 | How far back absences count |
| No Login Short Days / Points | 5 / 3 | 5 to 9 days without a classroom login = 3 points |
| No Login Long Days / Points | 10 / 5 | 10 or more days = 5 points |
| Low Grade Threshold / Points | 70 / 3 | Any current grade below 70 (below C) = 3 points |
| Grade Drop Points | 2 | Any grade that fell at least one letter band (90/80/70/60) since two weeks ago |
| Alert Limit | 6 | Score at or above this alerts the advisor and checks in with the student |
| Alert Cooldown Days | 7 | No second alert for the same student within this many days |

Jordan: 2 absences (4) + 5 days without login (3) = **7**, which crosses the limit of 6.

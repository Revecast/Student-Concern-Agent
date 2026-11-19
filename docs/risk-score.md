# Risk score and risk reason (SCA-9, SCA-10, SCA-11)

## When it runs

`SCH – Score First Year Students` runs every night at **02:00 org time (Pacific), 05:00 Eastern**.
It scores every **Active, Freshman** term enrollment (`AcademicTermEnrollment`) and writes three
fields on the student Contact: **Risk Score**, **Risk Reason** and **Risk Scored At**.

## How the points add up

All values come from **Setup → Custom Metadata Types → Risk Score Setting → Default** (SCA-10).
Changing a value there takes effect at the next nightly run, and no deploy is needed.

| Signal | Default points | Setting fields |
|---|---|---|
| Each Absent class in the last 14 days | 2 each, up to 6 | Missed Class Points / Max Points / Window Days |
| No classroom login for 5–9 days | 3 | No Login Short Days / Points |
| No classroom login for 10+ days | 5 | No Login Long Days / Points |
| Any current grade below 70 (below C) | 3 | Low Grade Threshold / Points |
| Any grade down a letter band in two weeks | 2 | Grade Drop Points |

The alert limit is **6** (`Alert Limit`). Tardy does not count as a missed class.

Absences are counted by a small Apex action, `StudentAbsenceCounter`, because Flow cannot read
attendance in this org (ADR-012). Everything else happens in the flow.

## The risk reason (SCA-11)

The reason names each signal that added points, in plain words, separated by semicolons. It is
**blank when the score is 0**.

| Student (demo) | Score | Reason |
|---|---|---|
| Jordan | 7 | Missed 2 classes in the last 14 days; no classroom login in 5 days |
| Avery | 5 | No classroom login in 11 days |
| Quinn | 4 | Missed 1 class in the last 14 days; grade dropped a letter in BIO 101 |
| Casey | 3 | Grade below C in BIO 101 |
| Alex | 0 | *(blank)* |

Wording rules: plain words, no jargon or blame, numbers as digits, course codes rather than full
course names, and "class"/"classes" kept singular or plural to match the count. The wording is
still waiting on the tone reviewer named for the demo.

## Testing at volume

`scripts/apex/load-bulk-test-students.apex` loads 220 synthetic students under the account
"DEMO - Bulk Test Students (safe to delete)". `scripts/apex/withdraw-bulk-test-students.apex`
sets them to Withdrawn so the nightly run skips them (ADR-014). On 2026-11-19 a single run scored
241 of 241 students, and every bulk score matched the expected value.

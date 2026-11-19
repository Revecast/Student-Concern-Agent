# Demo runbook — Student Concern Agent

> Built up story by story. The full walkthrough (alert, check-in, booking, crisis and handoff
> paths) is completed in SCA-45. This version covers reset and scoring.

## 1. Reset the demo (SCA-8)

Run from the repository root, with the Salesforce CLI signed in to the demo org:

```bash
scripts/load-demo-data.sh jaxedupde-dev-ed
```

- Safe to run any number of times. It updates the demo cohort in place and re-dates attendance and
  classroom logins relative to **today**. It never deletes anything.
- Creates the "Advisor" case team role if it is missing.
- Loads 21 fictional first-year students (emails at `student.jaxstate.example`, a reserved
  domain that never delivers): term enrollment (Freshman, Active), BIO 101 / ENG 101 / MATH 110
  sections, 4 class meetings per section in the last 14 days, simulated classroom activity, and an
  Advisee Record whose case team (role Advisor) is the assigned advisor.
- The assigned advisor defaults to the presenter (`ADVISOR_USERNAME` at the top of
  `scripts/apex/load-demo-data.apex`).

Expected scores after the next scoring run:

| Student | Signals | Score |
|---|---|---|
| **Jordan Rivera** | 2 absences (4) + 5 days without login (3) | **7 — alert** |
| Avery Chen | 11 days without login | 5 |
| Riley Patel | 2 absences | 4 |
| Quinn Okafor | 1 absence (2) + BIO grade dropped B to C (2) | 4 |
| Morgan Silva | 6 days without login | 3 |
| Casey Nguyen | BIO grade 65, below C | 3 |
| Taylor Brooks | 1 absence | 2 |
| 14 others | — | 0 |

**About the day counts.** "Days without login" is counted from the day you run the loader: each
student's last login is set to midday that many days earlier. The nightly scorer usually runs the
following morning, so by then every count is **one day higher** (Jordan shows 6 days, Avery 12,
Morgan 7). The scores do not change: the login points only step at 5 and 10 days, and the
absences are the most recent class meetings. Scores stay as in the table for about three days
after loading; reload before a demo to reset them.

**Finding the demo students.** Use the **Demo Students** list view on Contacts. It shows only the
21 demo students and leaves out the 220 synthetic bulk-test students (`DEMO - Bulk Test Students
(safe to delete)`), which are Withdrawn and never scored.

## 2. Score the students (SCA-9)

The scorer runs every night at 02:00 Pacific (05:00 Eastern). Reset the data before then and the
scores are ready in the morning.

To score straight away (a scheduled flow has no run-now button):

```bash
scripts/schedule-scoring.sh now 3      # runs in about 3 minutes
# wait, then check Jordan's Risk Score (7) and Risk Reason on his Contact
scripts/schedule-scoring.sh nightly    # put the 02:00 schedule back
```

How the points and the reason work: see [`risk-score.md`](risk-score.md). To test at volume,
see the bulk-test scripts described there.

## 3. Who can see which student (SCA-5)

Student records are **Private** (ADR-013): Account, Case and Opportunity are Private and Contact is
Controlled by Parent. An advisor sees a student because they are on:

1. the student's **account team** (role Advisor, Account access Read), which shows the Contact,
   risk fields and classroom activity; and
2. the student's **Advisee Record case team** (role Advisor), which shows the Advisee case. The
   flow `RT – Student Outreach – Share With Advisor` uses it to share every new outreach row with
   that advisor (Read).

The agent's running user (group Student Concern Agent User) has View All on student records.

**Changing a student's advisor:** update both teams. On the student's administrative account,
replace the Account Team member. On the Advisee Record case, replace the Case Team member. Flow
can't react to case team changes, so this isn't automatic. Outreach rows created earlier stay
shared with the previous advisor. The demo load sets both teams for the presenter.

## 4. What the advisor gets when a student is flagged (SCA-13, SCA-14)

When the nightly score rises from below 6 to 6 or more, and the student has not been alerted in
the last 7 days, `RT – Contact – Risk Crossing` calls `SUB – Alert Assigned Advisor`. It finds
the Advisor on the student's Advisee Record case team and gives that person:

1. a **Record Alert** on the student (Severity Warning, active for 7 days);
2. a **Task** on the Advisee case, due in two days, with the score and the plain-language reason;
3. a **Student Risk Alert** in-app notification (desktop and mobile). The text says only
   "Student check-in needed"; it names no student, because a phone can show it on a lock screen.

Each step is written to the outreach log. **No assigned advisor:** everything goes to the
**Advising Queue** instead and an extra log row records the Advising Queue exception. Nobody else
is ever alerted (ADR-001). The student's check-in is sent at the same time (ADR-014, SCA-15).

**Advising Queue members:** add people with
`sf apex run -f scripts/apex/add-advising-queue-member.apex -o <org>` (edit the username at the
top). Run it once after the demo load; by default it adds the presenter.

**Seeing it in the demo:** the Task shows in the student's Activity timeline and on the advisor's
home page; the notification appears under the bell. Advisors hold `DATA – Student Alerts – Update`
(through their permission set group) to read, snooze and close their alerts.

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

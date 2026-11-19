## UAT test users and fixtures (SCA-5, SCA-14, SCA-36)

UAT must prove that advisors see only their own students and that alerts land on the right person.
An admin can see everything, so these checks need non-admin users. Two scripts set them up in
`jaxedupde-dev-ed`. Both are safe to re-run.

### Run order

1. `sf apex run -f scripts/apex/setup-uat-users.apex -o jaxedupde-dev-ed`
2. `sf apex run -f scripts/apex/assign-uat-advisors.apex -o jaxedupde-dev-ed`

Run step 2 again after any reload of `load-demo-data.apex`, because the loader makes the presenter
the advisor of every demo student again. Setup records (users, permission sets) and data records
(team members) can't be changed in one transaction, which is why there are two scripts.

### Users

All four use the **Standard User** profile and the **Student Success Advisor** permission set group.
Usernames end in `@revecast.io.edupde`. The email on every user is the tester's, so the
password-setup emails go to the tester. The scripts never set or store a password.

| User | Username | Purpose |
|---|---|---|
| UAT Advisor One | `sca.uat.advisor1@revecast.io.edupde` | Assigned advisor of Avery Chen and Morgan Silva |
| UAT Advisor Two | `sca.uat.advisor2@revecast.io.edupde` | Assigned advisor of Riley Patel |
| UAT Advisor Unassigned | `sca.uat.unassigned@revecast.io.edupde` | Advisor with no students: must see none |
| UAT Counselor | `sca.uat.counselor@revecast.io.edupde` | Counseling Center queue member (placeholder, see below) |

The presenter stays the advisor of Jordan Rivera, so the demo story is unchanged.

### What assign-uat-advisors.apex changes

- On the Advisee case team **and** the account team of Avery, Morgan and Riley, it replaces the
  Advisor with the UAT advisor (ADR-013: changing an advisor means changing both teams).
  Account access is Read; case and opportunity access are None.
- It removes team **memberships** only. It deletes no student, case or account record.
- It creates **UAT No-Advisor Student** (email `uat.noadvisor@uat.student.jaxstate.example`, a
  reserved domain) with no advisor, to test the Advising Queue path.

### Queues

| Queue | Member | Note |
|---|---|---|
| Advising Queue | Presenter | Receives alerts for students with no assigned advisor |
| Counseling Center | UAT Counselor | **Placeholder** until the real crisis contacts are named (open answer 9) |

### Alert-path results, 2026-11-19

Run by raising a test student's Risk Score across the alert limit (6) in `jaxedupde-dev-ed`.

| Case | Action | Result |
|---|---|---|
| Assigned advisor | Avery Chen 5 → 7 | Task, record alert and in-app notification owned by UAT Advisor One; 2 outreach log rows (Task, In-App Notification), Exception Used = None; outreach shared to UAT Advisor One (Read) |
| No advisor | UAT No-Advisor Student blank → 7 | Task and record alert owned by Advising Queue; Exception Used = Advising Queue; a Skipped log row records "No assigned advisor on the Advisee Record" |
| Cooldown | Avery 7 → 5 → 7 the same day | No new task or log rows (one outreach per 7 days) |

After the test Avery's score was set back to 5 (her scored value). Her Risk Last Alerted Date stays
2026-11-19, so she won't alert again until 2026-11-26. To re-run case 1 sooner, clear that date first.

Jordan Rivera has a score of 7 and was never alerted. That's expected: his score first reached 7
before the crossing flow was deployed, and an alert fires only when the score **goes up across** the
limit. A score that stays at 7 never fires.

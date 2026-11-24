# Demo runbook — Student Concern Agent (SCA-45)

For the live demos on **2026-12-02 and 2026-12-03**. The presenter is **Sean Speer** (since
2026-11-24; it was Ernie Maldonado before), who is also the assigned advisor for all 21 demo
students (UAT advisors are also on Avery, Morgan and Riley). The scripts use Sean's username
(`sean.speer@jaxconsult.com.edudemopde`). The story: the nightly scorer
notices Jordan stopped logging in, his score crosses 6, and the alert, Task and bell notice reach
his advisor with nobody typing.

## 1. The evening before: reset

**Start before midnight Pacific (3:00 AM Eastern).** The script refuses once the org's date
(Pacific) equals the demo date. It takes about 10 minutes.

### Who runs it

Either works:

- **You, on your Mac** (recommended for the demo nights, so you see the result yourself):
  ```bash
  cd Student-Concern-Agent && git pull
  python3 scripts/demo-reset.py --demo-date 2026-12-02 --org sca-admin --dry-run   # look first
  python3 scripts/demo-reset.py --demo-date 2026-12-02 --org sca-admin             # type RESET
  ```
  Leave out `--yes`, so the script asks you to type RESET before it deletes anything.
  Needs **Python 3.9 or later** (it uses the standard `zoneinfo` module; no extra packages) and the
  Salesforce CLI (`sf`, tested with 2.151.7) signed in to the org (`sca-admin` on your
  Mac). macOS's built-in Python 3.9 from the Xcode tools is enough. Nothing else: no `jq`, no GNU tools.
- **Ask Orchestrate** in a Build session on this repo. It runs the same command against
  `jaxedupde-dev-ed` with `--yes` under your standing approval (deletes only Tasks, Record Alerts,
  Student Outreach rows and emails on the 22 students, after the export).

### What it does

1. Finds the 21 demo students and UAT No-Advisor Student (stops unless exactly 22).
2. Exports every leftover Task, Record Alert, Student Outreach row and email on them, all fields,
   to `demo-backups/<UTC time>/` (CSV and JSON; git ignores the folder), and prints the count by
   object and by student. Deletes only IDs in that export.
3. Deletes them one by one, stops at the first unexpected failure, then confirms 0 are left and
   clears Risk Last Alerted Date on the 22.
4. Loads the demo data dated to the demo day, with Jordan's last login 3 days back, and scores
   once now: Jordan 4, nobody at 6 or more, no alerts.
5. Reloads with Jordan's last login 5 days back and puts the scorer back on **02:00 Pacific**. It
   prints `Jordan's alert will arrive at <demo day> 02:00 PST`.

It never edits a risk score by hand and never deletes anything else. Deleted records stay in the
Recycle Bin for 15 days. (The 220 bulk-test students were deleted on 2026-11-21; if they are ever
reloaded with `scripts/apex/load-bulk-test-students.apex`, the script still leaves them out.)

### Clear the bell (manual)

Old bell notices from rehearsals stay in the bell; Salesforce keeps notifications for 90 days and
has no delete. The notifications API returned no notifications for this user when tried
(2026-11-21), so the script can't clear them. Before or after the reset, in the browser: click
the **bell → Mark all as read**. The only unread notice in the morning is then Jordan's.

## 2. Demo morning: check (2 minutes)

```bash
python3 scripts/demo-reset.py --org sca-admin --check
```

Read-only; it changes nothing. One PASS/FAIL line each:

| Check | PASS when |
|---|---|
| Jordan at 7, alerted today | Risk Score 7 and Risk Last Alerted Date = today |
| One alert, one open Task, two outreach rows | exactly one active Record Alert in the org and one open Task on the 22 students, both Jordan's and owned by you; two outreach rows (Task, In-App Notification) for Jordan, sent to you |
| No other demo student at 6 or more | nobody besides Jordan (UAT No-Advisor Student is not counted) |
| Scores match the expected table | all 21 match what the scoring rules give for this day (`scripts/crossing_table.py`) |
| Scorer ran today and is scheduled | all 21 scored today; one schedule, WAITING, next run 02:00 |

It ends with `READY: 5 of 5 checks passed` and exit code 0, or `NOT READY` and exit code 1.

## 3. Plan B: Jordan still at 4 on demo morning

The 02:00 run didn't fire or didn't finish. Run:

```bash
python3 scripts/demo-reset.py --org sca-admin --score-now
```

It schedules the scorer 2 minutes out, waits until all 21 are rescored, puts the 02:00 schedule
back, then runs `--check`. **About 3–4 minutes** (3 min 19 s when tried on 2026-11-21). Jordan
goes to 7 and the normal flows send the alert, Task and bell notice. It deletes nothing.

If `--check` still fails after that, look at Setup → Paused and Failed Flow Interviews.

## 4. Click path

You land in **Service Console**. Everything below is in the **Student Concern** app.

1. **App Launcher** (nine dots, top left) → type **Student Concern** → open it.
2. **Contacts** tab → list view picker → **Demo Students**. Pin it (pin icon) so it opens by
   default. It shows the 21 demo students with their scores: Jordan 7, Avery 5, Quinn 4, Riley 4,
   Casey 3, Morgan 3, Taylor 2, the other 14 at 0.
3. **Bell** (top right): one new notice, "Student check-in needed" / "A student on your caseload
   crossed the risk limit. Open the record for details." Point out it names no student.
4. Open **Jordan Rivera** from the list. Show:
   - the risk fields: Risk Score 7, Risk Reason "Missed 2 classes in the last 14 days; no
     classroom login in 5 days", Risk Scored At (02:00 today), Risk Last Alerted Date (today);
   - the Task "Check in with Jordan Rivera" (High, due in two days) in the Activity timeline, and
     the Record Alert "Check in with Jordan Rivera" where the page shows record alerts;
   - "Last Modified By" shows Andrew Purpura, not you: see section 7.
5. **Agentforce** icon (top right header) → **Student Success Advisor Agent**. Start a new
   conversation for each prompt and type exactly:
   - `Summarize my student Jordan Rivera` → four numbered sections (Risk, Attendance, Grades,
     Recent outreach). "Recent outreach: None yet." is correct: the advisor alert isn't outreach
     to the student.
   - `Draft an outreach email to Jordan Rivera` → a warm draft to Jordan only, no "risk" or
     "score". Say: the agent drafts, the advisor sends; there is no send action.
   - `My student told me he wants to hurt himself. What should I do?` → the fixed crisis reply
     (911, 988, Counseling Center), and nothing else.
6. **Optional: the Counselor notice.** Only at the very end, because it adds a Task and two
   outreach rows to the student (and `--check` would then fail until the next reset).
   - Have a second browser (private window) logged in as **UAT Counselor**.
   - As yourself: App Launcher → **SF – UAT Send Message Tester** → student email
     `jordan.rivera@student.jaxstate.example`, Recipient role **Counseling Center**, **Crisis** on,
     Subject `Demo`, Body `Demo only` → Next.
   - In the Counselor's window: bell → "Urgent student follow-up needed." / "Open the task." →
     it opens the High-priority Task for the Counseling Center queue. No student name in the notice.

### Don't click

- **All Contacts, My Contacts, Recently Viewed** on Contacts, and global search for words like
  "Student": they mix the demo students with UAT No-Advisor Student and the org's sample contacts
  (Edge, GenePoint, United Oil and similar). UAT No-Advisor Student's risk score is blank on purpose
  (cleared 2026-11-21). Use the Demo Students list view and search by full name.
- **Edit** on the risk fields, or Setup → Flows → Debug/Run on the scorer: it changes scores.
- The UAT Send Message Tester before the main walkthrough is done.
- Prompt Builder previews with other students: not needed, and slow on stage.

## 5. The second day

Evening of 2026-12-02, before midnight Pacific:

```bash
python3 scripts/demo-reset.py --demo-date 2026-12-03 --org sca-admin   # type RESET
```

Then mark the bell read, and on 2026-12-03 run `--check` again. Day 2 then looks exactly like day
1, with today's dates.

If you skip it: on 12/3 Jordan is still 7, but his alert, Task and bell notice are dated 12/2
(the 7-day cooldown stops a second alert), so `--check` fails its first line; nobody else alerts
on 12/3. Other students start crossing on 12/5 (section 6).

## 6. How long a reset holds

Data dated to demo day D ages each night. Without another reset, the nightly run alerts you about:

| Night (02:00 Pacific) | Student | Score |
|---|---|---|
| D | Jordan Rivera | 4 → 7 (the demo) |
| D + 3 | Quinn Okafor | 4 → 7 |
| D + 4 | Riley Patel, Casey Nguyen | 4 → 7, 3 → 6 |
| D + 8 | Taylor Brooks | 5 → 7 |

So **12/3 is safe after a 12/1 reset for 12/2**: no new alert on 12/3. The full day-by-day table
for any load: `python3 scripts/crossing_table.py --demo-date <D>` (read-only; it replays the
scoring rules, and it predicted Quinn's real 11/21 alert from the earlier load).

## 7. Who the scorer runs as

The scheduled scorer runs as the org's **Default Workflow User** (Salesforce behaviour for
schedule-triggered flows on API 53 and later), which here is **Andrew Purpura**. That is why
Jordan's page shows him as Last Modified By after 02:00, and why the outreach rows are owned by
him. To show your name instead, an admin changes **Setup → Process Automation Settings → Default
Workflow User** to you. That affects every scheduled flow and workflow in the org, so for the
demo it's simpler to expect Andrew's name. (The setting isn't deployable metadata.)

## 8. Plain data reload (no reset)

`scripts/load-demo-data.sh <org>` reloads the cohort dated to today without deleting anything or
scoring. Prefer `demo-reset.py` before a demo.

## 9. Background: who can see which student (SCA-5)

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

## 10. Background: what the advisor gets when a student is flagged (SCA-13, SCA-14)

When the nightly score rises from below 6 to 6 or more, and the student has not been alerted in
the last 7 days, `RT – Contact – Risk Crossing` calls `SUB – Alert Assigned Advisor`. It finds
the Advisor on the student's Advisee Record case team and gives that person:

1. a **Record Alert** on the student (Severity Warning, active for 7 days);
2. a **Task** on the Advisee case, due in two days, with the score and the plain-language reason;
3. a **Student Risk Alert** in-app notification (desktop and mobile). The text says only
   "Student check-in needed"; it names no student, because a phone can show it on a lock screen.

Each step is written to the outreach log. **No assigned advisor:** everything goes to the
**Advising Queue** instead and an extra log row records the Advising Queue exception. Nobody else
is ever alerted (ADR-001). **Nothing is sent to the student.** The student check-in (SCA-15) is
not built yet; when it is, it is meant to go out at the same time as the advisor alert (ADR-014).

**Advising Queue members:** add people with
`sf apex run -f scripts/apex/add-advising-queue-member.apex -o <org>` (edit the username at the
top). Run it once after the demo load; by default it adds the presenter.

**Seeing it in the demo:** the Task shows in the student's Activity timeline and on the advisor's
home page; the notification appears under the bell. Advisors hold `DATA – Student Alerts – Update`
(through their permission set group) to read, snooze and close their alerts.

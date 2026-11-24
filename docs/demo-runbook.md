# Demo runbook — Student Concern Agent (SCA-45)

For the live demos on **2026-12-02 and 2026-12-03**. The presenter is **Sean Speer** (since
2026-11-24; it was Ernie Maldonado before), who is also the assigned advisor for all 21 demo
students (UAT advisors are also on Avery, Morgan and Riley). The scripts use Sean's username
(`sean.speer@jaxconsult.com.edudemopde`). The story: the nightly scorer
notices Jordan stopped logging in, his score crosses 6, and the alert, Task and bell notice reach
his advisor with nobody typing.

## 1. Every night, automatically: the daily refresh

**Nobody runs anything before a demo.** Since 2026-11-24 a scheduled Apex job,
**Student Demo Daily Refresh** (`StudentDemoDailyRefresh`), runs every night at **01:30 Pacific**,
half an hour before the real scorer (02:00). Each run:

1. Moves the 21 demo students' attendance and last-login dates forward a day, so every student keeps
   the same story relative to today. The data no longer ages into surprise alerts.
2. Features **Jordan Rivera every day**, plus one other student in turn:

   | Day | Second student | Why they cross |
   |---|---|---|
   | 11/24, 11/27, 11/30, 12/3 … | Casey Nguyen (3 → 7) | missed 2 classes; grade below C in BIO 101 |
   | 11/25, 11/28, 12/1 … | Quinn Okafor (4 → 8) | missed 3 classes; grade dropped a letter in BIO 101 |
   | 11/26, 11/29, 12/2 … | Taylor Brooks (2 → 7) | missed 2 classes; no classroom login in 6 days |

   It gives them the "crossing" version of their story and sets their score back to yesterday's
   value (below 6) with Risk Last Alerted Date cleared.
3. Closes earlier days: older Record Alerts on the demo students are switched off and older open
   "Check in with …" Tasks are marked Completed. **Nothing is deleted** (the outreach log keeps
   every day's rows).

At **02:00** the real scorer runs; Jordan and the day's second student go over 6 and the normal
flows send Sean the alert, Task and bell notice. The job never writes the score that triggers an
alert. It only lowers a featured student's score, which the crossing flow ignores.

Only Casey, Quinn and Taylor rotate because their only assigned advisor is Sean. Avery, Morgan and
Riley also have UAT advisors, so their alerts could go to someone else.

**Turn it off:** Setup → Scheduled Jobs → delete **Student Demo Daily Refresh**. Turn it back on:
`System.schedule('Student Demo Daily Refresh', '0 30 1 * * ?', new StudentDemoDailyRefresh());`
(or `StudentDemoDailyRefresh.scheduleNightly();`) in anonymous Apex.

The old evening reset (`demo-reset.py --demo-date …`) still works for a full clean-up, but it is
no longer needed. If you use it, the refresh carries on from it the next night.

### The bell (optional)

Bell notices from earlier days stay in the bell (Salesforce keeps them 90 days and has no delete).
Unread ones pile up daily. **Mark all as read** whenever you like; that morning's notices arrive
new either way.

## 2. Any morning: check (2 minutes, optional)

```bash
python3 scripts/demo-reset.py --org sca-admin --check
```

Read-only; it changes nothing. One PASS/FAIL line each:

| Check | PASS when |
|---|---|
| Daily refresh 01:30 and scorer 02:00 scheduled | both jobs WAITING at those times |
| Featured students over 6 and alerted today | Jordan and the day's second student at 6 or more, Risk Last Alerted Date = today |
| One alert and one open Task per featured student, for you | exactly those two active alerts and two open "Check in with" Tasks on demo students, owned by the presenter |
| Nobody else at 6 or more | UAT No-Advisor Student is not counted |
| Scores match today's expected table | all 21 match the stories in section 1 |
| Scorer ran today | all 21 scored today |

It ends with `READY: 6 of 6 checks passed` and exit code 0, or `NOT READY` and exit code 1.
First run on 2026-11-24 14:05 Pacific: 6 of 6.

## 3. Plan B: Jordan still at 4 in the morning

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
   default. It shows the 21 demo students with their scores: Jordan 7, Avery 5, Riley 4, Morgan 3,
   the other 14 at 0, and Casey, Quinn and Taylor at their normal score except the one featured
   today, who is at 7 or 8 (section 1).
3. **Bell** (top right): two new notices (Jordan's and the day's second student's), "Student check-in needed" / "A student on your caseload
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

Nothing to do: the daily refresh sets it up again overnight. On 12/3 Jordan has a fresh alert,
Task and bell notice dated 12/3, and the second student is Casey (12/2 it is Taylor).

## 6. How long it holds

Indefinitely, while the job is scheduled: every night gives the same picture with that day's
dates. (Before 2026-11-24 the data aged and other students started alerting a few days after a
reset; `scripts/crossing_table.py` models that older behaviour.)

## 7. Who the scorer runs as

The scheduled scorer runs as the org's **Default Workflow User** (Salesforce behaviour for
schedule-triggered flows on API 53 and later), which here is **Andrew Purpura**. That is why
Jordan's page shows him as Last Modified By after 02:00, and why the outreach rows are owned by
him. To show your name instead, an admin changes **Setup → Process Automation Settings → Default
Workflow User** to you. That affects every scheduled flow and workflow in the org, so for the
demo it's simpler to expect Andrew's name. (The setting isn't deployable metadata.)

## 8. Plain data reload (no reset)

`scripts/load-demo-data.sh <org>` reloads the cohort dated to today without deleting anything or
scoring. The daily refresh moves the dates on from there the next night.

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

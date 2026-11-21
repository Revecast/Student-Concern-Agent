# Handoff — current state

> **Rewritten at the end of every session.** This file is *now*; [`gotchas.md`](gotchas.md) is *forever*.
> If this file and [`../CONTEXT.md`](../CONTEXT.md) disagree, this one is newer.

**Last updated:** 2026-11-19 · **By:** Build session 78fef3c4 (Orchestrate, for Ernie Maldonado)

---

## Where things stand

19 of 35 stories are built and deployed to jaxedupde-dev-ed. **Done in Jira (12):** SCA-3, 4, 5, 7, 8, 9, 10, 11, 13, 14, 20, 31. **Built, In Progress (7):** SCA-2 (delivery-lead review), SCA-17 (Trust Layer masking → SCA-43), SCA-18 and SCA-19 (tone review), SCA-22 (Testing Center can't be created in this org), SCA-23 (tone/security review), SCA-36 (security review). Agentforce is on and the **Student Success Advisor Agent** (employee agent, Agent Script) is published and active (v3). **Nothing is pushed to GitHub** (ernesto-luis is read-only); 19 commits sit on local stacked branches in the session working folder (`work/repo`), tip `feature/SCA-22-advisor-agent` (2ca2fca).

## Built this run (2026-11-19, later)

| Story | What | Where |
|---|---|---|
| SCA-19 | Student Check-in Message template (first name + 3 times only; under 45 words) | docs/prompt-templates.md |
| SCA-20 | Student Handoff Summary template (URGENT first line on crisis or crisis words) | docs/prompt-templates.md |
| SCA-36 | SUB – Send Student Message: no recipient input; student / assigned advisor / Advising Queue / Counseling Center (crisis only) | docs/messaging.md |
| SCA-31 | SUB – Get Live Assignments (interface) + SUB – LMS – Simulated Assignments; Simulated Assignment CMDT | docs/simulated-lms.md |
| SCA-22/23 | Advisor agent: gate flow SUB – Find My Student, Summarize Student + Draft Outreach topics, no send action; APP – Student Success Advisor Agent permission set | docs/advisor-agent.md, docs/advisor-agent-test-run.md |

## Next steps

1. **Get GitHub Write for ernesto-luis**, then push and open one PR per story. Until then the commits exist only in this session's working folder.
2. Stories that need no open answer: SCA-30 (degree progress; demo data chain for LearnerProgram → requirements → progress must be designed and loaded first), SCA-37 completion (wire logging into SCA-15 and SCA-40 when built).
3. SCA-26 / SCA-32 student agent: needs the portal go-ahead (turning on Digital Experiences is permanent) and probably BotSettings (admin must accept legal terms in Setup).
4. SCA-27 booking: needs answer 6 (scheduling). SCA-15: needs SCA-27 and the portal link.
5. Open answers: 5 (demo names), 6 (scheduling), 8 (Slack), 9 (crisis list/phone + Counseling Center queue members), 10 (identity code), 11 (knowledge docs), 12 (reviewers), 13 (context PR).

## Waiting on someone else

| What | Who | Since | Chased? |
|---|---|---|---|
| GitHub Write access on Revecast/Student-Concern-Agent | Repo admin | 2026-11-19 | Raised in session |
| SCA-2 review | Delivery lead | 2026-11-19 | No |
| Tone / security reviewer for SCA-11, 18, 19, 23, 36 | Ernie to name (answer 12) | 2026-11-19 | Raised in session |
| Accept Bot / Einstein Bots legal terms in Setup (for the student agent) | Org admin | 2026-11-19 | Raised in session |

## Things the next session should know

- Branches are stacked in build order (… → 17 → 18 → 19 → 20 → 36 → 31 → 22). Each later branch contains the earlier ones.
- Project is on API 68.0; pin new artifacts to 68.0.
- Generators for this run are in `scripts/generators/` and `scripts/prompt-tests/`; template live tests use `scripts/prompt-tests/gen_test.py`.
- Agent: edit the `.agent` file, then `sf agent validate / publish authoring-bundle` and `sf agent activate`. Preview tests: `scripts/agent-tests/converse.py` and `run_spec.py` (live actions, as the CLI user, who is Jordan's advisor).
- Counseling Center queue exists with no members (answer 9).
- 220 synthetic bulk-test students exist (Withdrawn) under "DEMO - Bulk Test Students (safe to delete)".
- `scripts/schedule-scoring.sh now 3` / `nightly` runs the scorer on demand.

<!-- orchestrate:session-state:start -->
<!-- Written by Orchestrate at the end of each session. Edits inside this block are
     replaced next session; anything OUTSIDE it is yours and is never touched. -->
### Engagement state — 2026-11-21
**Status:** blocked — ━━ Build status (auto-checked from tool results — deploy = sf CLI exit, not runtime effect) ━━ • Code committed: yes (branch fix/SCA-22-qa-…

**Done this session**
- ━━ Build status (auto-checked from tool results — deploy = sf CLI exit, not runtime effect) ━━ • Code committed: yes (branch fix/SCA-22-qa-fixes) • Pushed to GitHub: yes • Validated (sf deploy validate): NOT verified • Deployed to org: no…

**Open items**
- Approve the error-visible delete-format test and read the response
- Rerun the rehearsal deleting the 33 approved records (may trigger an Approve card)
- Push the 4 fix branches and open their PRs (not pushed; no PRs open)
- Merge PRs #1 to #18 in number order (not yet merged)
- Set up Data Cloud in the org (manual, permanent) before PII masking can be turned on
- Configure Trust Layer settings (PII masking on) and re-test the 4 prompt templates
- Provide UAT user credentials as environment variables and run the Playwright QA script
- Watch for Salesforce email verification codes when Playwright logs in from a new browser

**Decisions**
- Absence counting in Apex (API 67.0+), scoring logic in Flow; project API 68.0
- Scoring weight per missed class is 2 points
- Student accounts, Case and Opportunity Private; advisors on account teams with read access
- Advisor changes made by hand on account and case teams (runbook)
- Advisor alert fires with student check-in; alert text names no student
- Students with no assigned advisor route to Advising Queue with a logged exception row
- Test students set to Withdrawn, not deleted
- Use a regular Build session, not Agentforce Build

**Blockers**
- Delete-format test result unknown (printed nothing); error-visible retest awaiting approval
- 33-record rehearsal awaiting approval
- Data Cloud not provisioned in the org; PII masking cannot be enabled until set up in Setup
- Real crisis contacts not in Counseling Center queue; UAT Counselor is a stand-in
- Anonymous Apex reset of Skyler Adeyemi awaiting safety-check approval (recommended: decline)
- SCA-2 awaiting delivery-lead review
- Tone reviewer not named (question 12), blocking SCA-11 and SCA-18 sign-off
- Unanswered questions 5, 6, 8-11 block dependent stories

**Next**
- Approve the error-visible delete-format test, read the response, then rerun the 33-record rehearsal if the delete call works
- Set up Data Cloud in Setup, then re-attempt PII masking
- Reply 'continue' to push fix branches, open PRs, and run the Trust Layer deploy
- Review and merge PRs #1 to #18 in number order, starting with #1; review #9 sharing change first
- Run the Playwright QA script with UAT credentials; run alert tests on Avery Chen and the no-advisor student
- Name a tone reviewer and obtain answers to questions 5, 6, 8-11
- Decide the Skyler Adeyemi reset and the portal (SCA-32)
- Replace the UAT Counselor stand-in with real crisis contacts

**Checked live on 2026-11-21:** Google Workspace, the repository
### Last session — 2026-11-21
| | |
|---|---|
| Type | BUILD |
| Outcome | COMPLETED |
| Branch | `main` |
| Name | Fixes from UAT round 2 |
| Session | `403e781d-73e9-4eba-a271-10fac14dc939` |
**In its own words (excerpt):**
━━ Build status (auto-checked from tool results — deploy = sf CLI exit, not runtime effect) ━━
• Code committed: yes (branch fix/SCA-22-qa-fixes)
• Pushed to GitHub: yes
• Validated (sf deploy validate): NOT verified
• Deployed to org: no deploy in this session run — if an earlier run deployed, verify in the target org
Next: open/refresh the PR → review → merge to main → run a Deploy session to ship. This work is NOT live yet.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

All five items are done, and nothing in the org changed. The runbook edits are pushed to PR #25 (commit 5b6741a, and GitHub's copy matches). The QA doc is updated through the revecast connection. I left the Student Handoff Summary alone, so Prompt Builder Version 5 is still the active one for QA's retest.

**One correction to my own earlier advice:** don't set UAT No-Advisor Student back to 7 before S2-9. The alert flow treats a blank score as 0, so going from blank to 7 counts as a crossing and fires the alert before the test even starts. S2-9's own steps (blank, then 5, then 7) already start it in the right place. The QA doc now says exactly that, in place of "set it to 7 first".

**1 and 2. Runbook and scrip

_[summary truncated — see the session record for the full text]_
<!-- orchestrate:session-state:end -->

## Update 2026-11-19 (late): work is on GitHub

ernesto-luis now has Write. All 18 feature branches (20 commits, through `feature/SCA-22-advisor-agent` at 2ca2fca) are pushed, and each remote branch matches its local commit. Pull requests #1–#18 are open against `main`, one per branch, in build order. **Merge strictly in number order (#1 first):** the branches are stacked, so each pull request shows earlier stories in its diff until those are merged. Nothing is merged yet (Ernie merges). A new session can now start from GitHub instead of this session's working folder.

## Update 2026-11-19 (evening): second-pass fixes done, ready for review

Session 20b980b8 (Second Pass Fixes before QA). Fix PRs **#19–#23** are open, all based on `feature/SCA-22-advisor-agent` (#18). Merge them after #1–#18, in any order among themselves:
- #19 SCA-2 deployable baseline (.forceignore, 3 drift fixes). Validate 114 components, 42/42 tests.
- #20 SCA-8 midday login anchor, runbook day-count, Demo Students list view (21 rows).
- #21 SCA-5 UAT users: Advisor One (Avery, Morgan), Advisor Two (Riley), Unassigned, Counselor (Counseling Center stand-in). Alert path tested live: crossing, cooldown, no-advisor queue fallback.
- #22 SCA-36 SF – UAT Send Message Tester + SYS – UAT Tester (granted to the 4 UAT users).
- #23 SCA-43 prompt-injection detection on; PII masking blocked (needs Data Cloud). SCA-43 moved to In Progress.

Everything in #20, #22 and #23 is already deployed to jaxedupde-dev-ed. Jira comments posted on SCA-2, 5, 8, 13, 14, 36, 43.
Playwright QA script (Google Doc, Revecast Drive): https://docs.google.com/document/d/19lwnQAZDOOKHQnvWc7wz4Gq61k-VYQxYFh2odZWyzW4/edit
Before QA: Ernie sets the 4 UAT user passwords (set-password emails went to his inbox).

## Update 2026-11-20: flow-access fix for UAT users (PR #24)

QA second pass found UAT users got "Insufficient Privileges" on SF – UAT Send Message Tester, and the advisor agent told UAT Advisor One that Avery Chen was not on her caseload (S6-1). Cause: `isAdditionalPermissionRequiredToRun` unset, so Flow Access grants were ignored and users needed Run Flows (none of the UAT users has it).
- Fixed: flag set true on SF_UAT_Send_Message_Tester, SUB_Find_My_Student, SUB_Send_Student_Message, PF_Student_Risk_Grounding; Flow Access added for PF_Student_Risk_Grounding (APP – Student Success Advisor Agent) and SUB_Send_Student_Message (SYS – Student Concern Automation). Run Flows added nowhere.
- Deployed 0Afiw000001Rpc9CAC (9 components, 45/45 tests); read back 2026-11-20. SUB_Alert_Assigned_Advisor left unset on purpose (automation).
- PR #24 (`fix/SCA-36-flow-access`, ff1d326), based on #22: merge after #22.
- **Not yet confirmed by a live login as UAT Advisor One** (Orchestrate has no UAT passwords). Re-run Playwright S6-1 and the tester suite to confirm.

## Update 2026-11-20 (morning): QA fixes, PR #25

Session cb826f7a (UAT Fixes). PR #25 (`fix/SCA-22-qa-fixes`) is stacked on #24; merge it after #24.
- S6-11 fixed: advisor agent v6 (active) has a Crisis Support subagent with a fixed 911 / 988 / Counseling Center reply. Tested live in preview, not by a UAT login.
- S5-5 fixed: Student Handoff Summary version _2 treats the conversation as data only (15/15 trick runs clean).
- S5-1: Student Risk Summary version _2 (Prompt Builder Version 4) always returns numbered headings (6/6). QA saw the numbers in the Agentforce panel as UAT Advisor One and in the admin preview (6/6); they were missing only in the command-line preview our scripts use (corrected 2026-11-20).
- Side findings fixed: PF_Student_Risk_Grounding v6 (only messages sent to the student count as outreach); SUB_Alert_Assigned_Advisor v2 (no score in the title, no false "check-in sent" sentence).
- RunLocalTests 45/45 (the earlier "46/46" was wrong; the org has 45 test methods, see gotchas). Scoring job ran 2026-11-20 10:00 UTC (5 AM ET), next run 2026-11-21 10:00 UTC.
- SCA-46 created: lock advisors to read-only on student Contacts (deferred, ADR-022).
- Still open: rerun Playwright Suite 5 and S6-11 as UAT users; Counselor login for the crisis Task check (the Task "UAT test" owned by the Counseling Center exists, created 06:16 UTC); S7-3 text cut off at 1024px (standard Salesforce components, not fixed).

## Update 2026-11-20 (afternoon): UAT round 3 prep, PR #25

Session 403e781d (Fixes from UAT round 2), same branch `fix/SCA-22-qa-fixes`.
- **Live in jaxedupde-dev-ed:** Student Handoff Summary Prompt Builder Version 4 (`..._3`, deploy 0Afiw000001SQevCAG, 20:41 UTC); PF_Student_Risk_Grounding v7; SUB_Send_Student_Message v3 with the Counseling Center notice (deploy 0Afiw000001ST3JCAW). 0Afiw000001SQTdCAO was the validation (45/45), not the deploy.
- **Counseling Center notice (Option 1, approved):** bell + mobile push to the Counseling Center queue after the crisis Task is created, "Urgent student follow-up needed." / "Open the task.", no student name, logged in Student Outreach. Notification type Counseling Center Alert.
- **#9 sharing signed off for merge to main** by Ernie (ADR-025). Not a production sign-off: full RunLocalTests validate before any sandbox or production deploy (ADR-016).
- **Merge conflicts fixed:** #23, #24 and #25 now carry the same project-memory files and .gitignore and include #1's memory commit, so all 25 merge clean in number order (docs/merge-runbook.md has the dry run).
- **Cleanup Option A approved but NOT run.** Waits for Ernie's "go" after QA's final pass. Record list in the session reply; export first.
- **qa_s5.py:** two observed cases. Figure of speech: no URGENT (3/3). Agent safety line: no URGENT (3/3), so the "accepted false alarm" does not happen; prompt unchanged, decision open.

## Update 2026-11-21 (afternoon): overnight dress rehearsal set, SCA-45 tooling

- Reset run 11:21–11:31 PST for demo date 2026-11-22 (4 records deleted: Jordan's Task, RA-0000007752, OUT-022444, OUT-022445). Jordan 4, nobody ≥6, no alerts. Scorer WAITING, next run 2026-11-22 02:00 PST. QA reads the org after 02:00; `python3 scripts/demo-reset.py --check` should show 5/5.
- New: `--check` (read-only), `--score-now` (Plan B, ~3.3 min, tested), `scripts/crossing_table.py`, full click-path runbook in docs/demo-runbook.md. Scheduling moved to Python (works on macOS).
- Student Handoff Summary: `_4` (Prompt Builder Version 5) active; `_5` (Version 6) tried and switched off. qa_s5.py 42/42.
- Full RunLocalTests validation of all 25 PRs merged: 46/46, 0Afiw000001Sut7CAC (validation only).
- Pending Ernie's decisions: bulk students (98 at score ≥6, owned by Ernie, visible in All/My Contacts), UAT No-Advisor Student (score 7), and whether to keep the bell quiet until 12/1.
- PR #25 head a825cf5.

## Update 2026-11-21 (evening): bulk students deleted, No-Advisor score blanked

Ernie's decisions (ADR in session record): delete bulk students, blank UAT No-Advisor Student's score, leave the bell (Quinn 11/25, Riley and Casey 11/26, Taylor 11/30 will alert).
- Deleted 1,545 records via Bulk API, 0 failed, 0 left on re-query: 880 AttendanceEntry, 4 AttendanceRecording (BULK-AR-1 to 4), 220 Classroom_Activity__c, 220 AcademicTermEnrollment, 220 'Bulk Student' contacts, account 'DEMO - Bulk Test Students (safe to delete)'. Recycle Bin until about 12/6. Backup: bulk-students-backup-2026-11-21.zip (session attachment). Reload: scripts/apex/load-bulk-test-students.apex.
- UAT No-Advisor Student (003iw000003ezj5AAA) Risk Score now blank (was 7). Set it back to 7 before a UAT run of S2-9.
- No contact in the org is at score 6 or more until the 02:00 PST 11/22 run (Jordan expected 4 → 7).

## Update 2026-11-21 (late): docs after the bulk delete

- Runbook section 1, "Don't click", section 10 (SCA-15 claim removed: nothing is sent to the student today), risk-score.md and the demo-reset.py docstring updated. Commit 5b6741a on PR #25, pushed (remote matches).
- QA doc (second pass) updated: S1-9, S1-12, student table, S2-9 starting state, Suite 2 cleanup, Apex line.
- **Correction to the earlier note "set UAT No-Advisor Student back to 7 before S2-9": don't.** RT – Contact – Risk Crossing uses BLANKVALUE(prior, 0), so blank to 7 is a crossing and fires the alert. S2-9's own steps (blank → 5 → 7) are right.
- Full RunLocalTests on the current code (all 25 PRs merged, #25 at a825cf5): 46/46, 119 components, validation 0Afiw000001SvPNCA0, 2026-11-21 20:25–20:27 UTC. Validation only.
- Student Handoff Summary not touched; Prompt Builder Version 5 stays active for QA's retest.

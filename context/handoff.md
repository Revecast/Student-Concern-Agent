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
### Engagement state — 2026-11-20
**Status:** blocked — ━━ Build status (auto-checked from tool results — deploy = sf CLI exit, not runtime effect) ━━ • Code committed: yes (branch fix/SCA-36-flo…

**Done this session**
- ━━ Build status (auto-checked from tool results — deploy = sf CLI exit, not runtime effect) ━━ • Code committed: yes (branch fix/SCA-36-flow-access) • Pushed to GitHub: yes • Validated (sf deploy validate): NOT verified • Deployed to org:…

**Open items**
- Push the 4 fix branches and open their PRs (not pushed; no PRs open)
- Merge PRs #1 to #18 in number order (not yet merged)
- Set up Data Cloud in the org (manual, permanent) before PII masking can be turned on
- Configure Trust Layer settings (PII masking on) and re-test the 4 prompt templates
- Provide UAT user credentials to Claude as environment variables and run the Playwright QA script (credentials handed over, run not yet done)
- Watch for Salesforce email verification codes when Playwright logs in from a new browser
- Run alert tests on Avery Chen and the no-advisor student (Morgan Silva to be used for alert tests)
- Post Jira comments, including alert-test evidence on SCA-13

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
- Data Cloud not provisioned in the org; PII masking cannot be enabled until a person sets it up in Setup
- Real crisis contacts not in Counseling Center queue; UAT Counselor is a stand-in
- Anonymous Apex reset of Skyler Adeyemi awaiting safety-check approval (recommended: decline)
- SCA-2 awaiting delivery-lead review
- Tone reviewer not named (question 12), blocking SCA-11 and SCA-18 sign-off
- Unanswered questions 5, 6, 8-11 block dependent stories
- Portal go-ahead (SCA-32) awaiting explicit approval
- AttendanceEntry unusable from Flow in this org (workaround in Apex)

**Next**
- Reply 'continue' to push fix branches, open PRs, and run the Trust Layer deploy (approval cards may appear)
- Set up Data Cloud in Setup, then re-attempt PII masking
- Review and merge PRs #1 to #18 in number order, starting with #1; review #9 sharing change first
- Run the Playwright QA script with UAT user credentials; run alert tests on Avery Chen and the no-advisor student
- Name a tone reviewer and obtain answers to questions 5, 6, 8-11
- Decide the Skyler Adeyemi reset and the portal (SCA-32)
- Replace the UAT Counselor stand-in with real crisis contacts

**Checked live on 2026-11-20:** the repository
### Last session — 2026-11-20
| | |
|---|---|
| Type | BUILD |
| Outcome | COMPLETED |
| Branch | `main` |
| Name | Second Pass Fixes before QA |
| Session | `20b980b8-1be2-4706-be68-d85ccb05103a` |
**In its own words (excerpt):**
━━ Build status (auto-checked from tool results — deploy = sf CLI exit, not runtime effect) ━━
• Code committed: yes (branch fix/SCA-36-flow-access)
• Pushed to GitHub: yes
• Validated (sf deploy validate): NOT verified
• Deployed to org: no deploy in this session run — if an earlier run deployed, verify in the target org
Next: open/refresh the PR → review → merge to main → run a Deploy session to ship. This work is NOT live yet.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The fix is deployed and checked against the org, and it's in a pull request. One part isn't done: I haven't confirmed it with a real login as UAT Advisor One.

**What your approved command found**

| Flow | Extra-permission setting | Active version |
|---|---|---|
| SF – UAT Send Message Tester | on | v2 |
| SUB – Find My Student | on | v2 |
| SUB – Send Student Message | on | v2 |
| PF – Student Risk Grounding | on | v5 |
| SUB – Alert Assigned Advisor | off, on purpose (automation) | — |

None of the four UAT users has Run Flows. All four now have Flow Access to all four flows. The script changed nothing in the org.

**Your four requests**
1. **Tester flow:** done. The setting is on, so the SYS – UAT Teste

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

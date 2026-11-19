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
### Engagement state — 2026-11-19
**Status:** blocked — ━━ Build status (auto-checked from tool results — deploy = sf CLI exit, not runtime effect) ━━ • Code committed: yes (branch fix/SCA-43-tru…

**Done this session**
- ━━ Build status (auto-checked from tool results — deploy = sf CLI exit, not runtime effect) ━━ • Code committed: yes (branch fix/SCA-43-trust-layer) • Pushed to GitHub: yes • Validated (sf deploy validate): yes • Deployed to org: yes — jax…

**Open items**
- Push the 4 fix branches and open their PRs (not pushed; no PRs open)
- Merge PRs #1 to #18 in number order (not yet merged)
- Configure Trust Layer settings (PII masking on) and re-test the 4 prompt templates
- Run alert tests on Avery Chen and the no-advisor student
- Post Jira comments, including alert-test evidence on SCA-13
- Write the Playwright QA Google Doc
- Replace the UAT Counselor stand-in with real crisis contacts
- Name a tone reviewer and answer questions 5, 6, 8-11

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
- Real crisis contacts not in Counseling Center queue; UAT Counselor is a stand-in
- Anonymous Apex reset of Skyler Adeyemi awaiting safety-check approval (recommended: decline)
- SCA-2 awaiting delivery-lead review
- Tone reviewer not named (question 12), blocking SCA-11 and SCA-18 sign-off
- Unanswered questions 5, 6, 8-11 block dependent stories
- Portal go-ahead (SCA-32) awaiting explicit approval
- AttendanceEntry unusable from Flow in this org (workaround in Apex)

**Next**
- Reply 'continue' to push fix branches, open PRs, and run the Trust Layer deploy (approval cards may appear)
- Review and merge PRs #1 to #18 in number order, starting with #1; review #9 sharing change first
- Run alert tests on Avery Chen and the no-advisor student
- Name a tone reviewer and obtain answers to questions 5, 6, 8-11
- Decide the Skyler Adeyemi reset and the portal (SCA-32)
- Replace the UAT Counselor stand-in with real crisis contacts

**Checked live on 2026-11-19:** the repository, Jira, Google Workspace
### Last session — 2026-11-19
| | |
|---|---|
| Type | BUILD |
| Outcome | COMPLETED |
| Branch | `main` |
| Name | Second Pass Fixes before QA |
| Session | `20b980b8-1be2-4706-be68-d85ccb05103a` |
**In its own words (excerpt):**
━━ Build status (auto-checked from tool results — deploy = sf CLI exit, not runtime effect) ━━
• Code committed: yes (branch fix/SCA-43-trust-layer)
• Pushed to GitHub: yes
• Validated (sf deploy validate): yes
• Deployed to org: yes — jaxedupde-dev-ed · NOT read back from the org: the deploy's result listed no components (run it with --json, and not --async, so Orchestrate can check the org)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The fixes are finished. You can start your review session and merge the PRs. One thing didn't go to plan: PII masking can't be turned on in this org.

**QA doc for the Playwright agent:** [Student Concern Agent – Playwright QA Script (second pass)](https://docs.google.com/document/d/19lwnQAZDOOKHQnvWc7wz4Gq61k-VYQxYFh2odZWyzW4/edit?usp=drivesdk), on your Revecast Drive. It uses the four test advisors and the new message tester. Its alert tests use Morgan Silva, because Avery was already alerted today and the 7-day limit would correctly block a second alert. Before the run, set the four test users' passwords from the emails in your inbox.

**PRs to review (#19–#23):** all five are based on #18. Merge them after #1–#18, in any order among themselv

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

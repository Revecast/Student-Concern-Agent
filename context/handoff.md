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
**Status:** on track — All 18 feature branches pushed to GitHub with 18 open PRs (#1-#18) against main; merge in number order, nothing merged yet.

**Done this session**
- Pushed all 18 feature branches (20 commits) to GitHub; each verified to match local, ending at feature/SCA-22-advisor-agent 2ca2fca
- Opened 18 pull requests against main, one per branch (#1 to #18), each with Jira story, changes, test steps, deployment notes
- Added a handoff note to project memory describing merge order

**Open items**
- Merge pull requests #1 to #18 in number order (not yet merged)
- Review #9: org-wide sharing change (accounts, cases, opportunities Private), live in jaxedupde-dev-ed
- Jira statuses unchanged; SCA-13 evidence comment and move to Done still open
- Commit and push the deployed SCA-13 source to the repository
- SCA-2 review by delivery lead
- SCA-17 still In Progress: Trust Layer masking unconfirmed (SCA-43)
- SCA-18 still In Progress: needs a named tone reviewer (question 12)
- Sf deploy validate not verified for the branches

**Decisions**
- Absence counting in Apex (API 67.0+) with scoring logic in Flow; project API 68.0
- Scoring weight per missed class is 2 points
- Student accounts, Case and Opportunity Private; advisors on account teams with read access
- Advisor changes done by hand on account and case teams (runbook)
- Advisor alert fires with student check-in; alert text names no student
- Students with no assigned advisor route to the Advising Queue, with a logged exception row
- Test students set to Withdrawn, not deleted
- Use a regular Build session, not Agentforce Build

**Blockers**
- Anonymous Apex reset of Skyler Adeyemi awaiting safety-check approval
- SCA-2 awaiting delivery-lead review
- Tone reviewer not named (question 12), blocking SCA-11 and SCA-18 sign-off
- Unanswered questions 5, 6, 8-11 block dependent stories
- Portal go-ahead (SCA-32) awaiting explicit approval

**Next**
- Review and merge PRs #1 to #18 in number order, starting with #1
- Review #9 sharing change before merging
- Run a Deploy session after merge to ship to the org
- Add SCA-13 evidence comment in Jira and move to Done
- Decide the Skyler Adeyemi reset (recommended: decline)
- Name a tone reviewer and obtain answers to questions 5, 6, 8-11
- Decide on the portal (SCA-32) to unlock the student agent

**Checked live on 2026-11-19:** the repository
### Last session — 2026-11-19
| | |
|---|---|
| Type | BUILD |
| Outcome | COMPLETED |
| Branch | `feature/SCA-2-prerequisites` |
| Name | Agent Build |
| Session | `78fef3c4-ef3b-4153-b3e9-9f1040d2ab70` |
**In its own words (excerpt):**
━━ Build status (auto-checked from tool results — deploy = sf CLI exit, not runtime effect) ━━
• Code committed: yes (branch feature/SCA-22-advisor-agent)
• Pushed to GitHub: yes
• Validated (sf deploy validate): NOT verified
• Deployed to org: no deploy in this session run — if an earlier run deployed, verify in the target org
Next: open/refresh the PR → review → merge to main → run a Deploy session to ship. This work is NOT live yet.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

All 18 branches are pushed and there are 18 open pull requests against `main`, one per branch. Nothing is merged.

**Pushed:** all 18 feature branches (20 commits). I checked each branch on GitHub against my local copy and all 18 point at the same commit, ending with `feature/SCA-22-advisor-agent` at `2ca2fca`. The work is safe on GitHub now, not just in this session.

**Pull requests:** each one lists its Jira story, what changed, how to test it, deployment notes and its current Jira status.

| # | Story | # | Story |
|---|---|---|---|
| [1](https://github.com/Revecast/Student-Concern-Agent/pull/1) | SCA-2 prerequisites | [10](https://github.com/Revecast/Student-Concern-Agent/pull/10) | SCA-13 risk cr

_[summary truncated — see the session record for the full text]_
<!-- orchestrate:session-state:end -->

## Update 2026-11-19 (late): work is on GitHub

ernesto-luis now has Write. All 18 feature branches (20 commits, through `feature/SCA-22-advisor-agent` at 2ca2fca) are pushed, and each remote branch matches its local commit. Pull requests #1–#18 are open against `main`, one per branch, in build order. **Merge strictly in number order (#1 first):** the branches are stacked, so each pull request shows earlier stories in its diff until those are merged. Nothing is merged yet (Ernie merges). A new session can now start from GitHub instead of this session's working folder.

# Handoff — current state

> **Rewritten at the end of every session.** This file is *now*; [`gotchas.md`](gotchas.md) is *forever*.
> If this file and [`../CONTEXT.md`](../CONTEXT.md) disagree, this one is newer.

**Last updated:** 2026-11-06 · **By:** <session or person>

---

## Where things stand

> **Not yet filled in.** — Where is the work right now, in two or three sentences? Someone picking
> this up cold reads this first.

## In progress

| What | State | Where it lives | Blocked on |
|---|---|---|---|
| | | | |

## Next steps

<!-- Ordered. The top item should be the one to do next, not the most interesting one. -->

1.

## Waiting on someone else

| What | Who | Since | Chased? |
|---|---|---|---|
| | | | |

## Things the next session should know

<!-- Anything true right now that is not obvious from the code: a half-finished refactor, a
     deliberately disabled test, a workaround that needs removing, a deploy that is half-applied.
     If you leave something in a strange state, this is where you say so. -->

-

<!-- orchestrate:session-state:start -->
<!-- Written by Orchestrate at the end of each session. Edits inside this block are
     replaced next session; anything OUTSIDE it is yours and is never touched. -->
### Engagement state — 2026-11-06
**Status:** on track — Backlog complete: 9 epics, 36 stories (113 pts), all in To Do. Design only, no build yet.

**Done this session**
- Created 9 epics and 36 stories (SCA-1 to SCA-45) with user stories, acceptance criteria, DoD, points, labels
- Verified Hard rules epic (SCA-33) child stories SCA-34 to SCA-37
- Applied never-rule label and criteria to 7 messaging/crisis/queue stories
- Confirmed all stories in To Do status

**Open items**
- Add Story Points field to SCA project so points display on boards and sprint reports
- Fill Story Points field on all 36 stories once field is added
- Verify epic links on 8 epics other than SCA-33 (SCA-1, SCA-6, SCA-12, SCA-16, SCA-21, SCA-25, SCA-38, SCA-41)
- Document design decisions to project memory before build session starts
- Execute SCA-2 (prerequisites check) as first build story to gate SMS, portal, Slack visibility

**Decisions**
- NEVER rule: student and assigned advisor only, plus two written exceptions
- Offering times rather than auto-booking
- Rule-based risk score calculation
- Fully simulated classroom system (no live data)

**Blockers**
- None

**Next**
- Save design decisions to SCA project memory
- Request Story Points field addition to SCA
- Verify remaining 8 epic links in Jira
- Schedule build session starting with SCA-2 prerequisites check

**Checked live on 2026-11-06:** Jira
### Last session — 2026-11-06
| | |
|---|---|
| Type | AGENTFORCE_BUILD |
| Outcome | COMPLETED |
| Branch | `main` |
| Name | Student Concern Agent Design |
| Session | `f2f57e59-6328-42c6-b8ce-9c0eb147c79c` |
**In its own words (excerpt):**
I created the backlog in SCA and checked it afterwards: 9 epics and 36 stories, SCA-1 to SCA-45, all in To Do.

**Correction:** I said 35 stories and 107 points before. The real count is **36 stories and 113 points**. All 36 were created as listed.

| Epic | Stories | Pts |
|---|---|---|
| [SCA-1](https://revecast.atlassian.net/browse/SCA-1) Foundation and prerequisites | SCA-2 to 5 | 9 |
| [SCA-6](https://revecast.atlassian.net/browse/SCA-6) Simulated classroom feed and risk score | SCA-7 to 11 | 15 |
| [SCA-12](https://revecast.atlassian.net/browse/SCA-12) Automatic trigger | SCA-13 to 15 | 10 |
| [SCA-16](https://revecast.atlassian.net/browse/SCA-16) Prompt templates | SCA-17 to 20 | 9 |
| [SCA-21](https://revecast.atlassian.net/browse/SCA-21) Advisor agent in Salesforce and Slack | SCA-22 to 24 | 8 |
| [SCA-25](https://revecast.atlassian.net/browse/SCA-25) Student agent on portal and SMS | SCA-26 to 32 | 27 |
| [SCA-33](https://revecast.atlassian.net/browse/SCA-33) Hard rules (Highest priority) | SCA-34 to 37 | 15 |
| [SCA-38](https://revecast.atlassian.net/browse/SCA-38) Handoffs | SCA-39 to 40 | 8 |
| [SCA-41](https://revecast.atlassian.net/browse/SCA-41) Testing, trust and m

_[summary truncated — see the session record for the full text]_
<!-- orchestrate:session-state:end -->

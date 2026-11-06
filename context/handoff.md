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
**Status:** on track — Design decisions saved to project memory. Ready for build; SCA-2 prerequisites check is first story.

**Done this session**
- Saved 5 architecture decision records (ADR-001 to ADR-005) to project memory
- Updated project summary with links to decisions and key facts
- Updated goals file with success criteria and open questions
- Updated environment file with demo org details and setup checks
- Added 3 known problems to project memory

**Open items**
- Add Story Points field to SCA project so points display on boards
- Fill Story Points field on all 36 stories once field is added
- Verify epic links on 8 epics (SCA-1, SCA-6, SCA-12, SCA-16, SCA-21, SCA-25, SCA-38, SCA-41)
- Execute SCA-2 (prerequisites check) as first build story to gate SMS, portal, Slack visibility

**Decisions**
- NEVER rule: student and assigned advisor only, plus two written exceptions (counseling center for crisis, advising queue if advisor unavailable)
- Offering times rather than auto-booking; re-offer if slot taken
- Rule-based risk score calculation with configurable points in settings
- Fully simulated classroom system (no live Canvas/Moodle yet)
- Use Salesforce built-in features before custom code; architecture decisions must be followed in build

**Blockers**
- None

**Next**
- Request Story Points field addition to SCA project
- Verify remaining 8 epic links in Jira
- Schedule build session starting with SCA-2 prerequisites check

**Checked live on 2026-11-06:** nothing — the status above is as recorded, not re-checked
### Last session — 2026-11-06
| | |
|---|---|
| Type | AGENTFORCE_BUILD |
| Outcome | COMPLETED |
| Branch | `main` |
| Name | Student Concern Agent Design |
| Session | `f2f57e59-6328-42c6-b8ce-9c0eb147c79c` |
**In its own words (excerpt):**
I saved the design to this project's memory and listed the files afterwards to check they're there. Later sessions on this project will load them automatically.

**The four decisions you made, plus the overall architecture, each in its own file:**

| File | What it records |
|---|---|
| ADR-001: contact rule | The agent contacts only the student and their assigned advisor, with two written exceptions: the counseling center when a student uses crisis words, and the advising queue when the advisor is unavailable. It also records how this is enforced: the messaging action can't take a recipient, crisis words are checked before the AI sees the message, and every outreach is logged. |
| ADR-002: booking | The agent offers 3 times and the student picks one. It doesn't book automatically. If a slot is gone at booking time, it offers fresh ones. |
| ADR-003: risk score | Points are given for missed classes, days without a login, a grade below C and a recent grade drop. An alert fires at 6 points or more, at most once a week per student. The points live in settings, so they can change without a redeploy. |
| ADR-004: classroom system | The classroom system is fully simulated, with sample da

_[summary truncated — see the session record for the full text]_
<!-- orchestrate:session-state:end -->

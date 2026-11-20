# Goals — Student Concern Agent

> What we are solving, how we will know it worked, and what the constraints are.

**Last reviewed:** 2026-11-06

## The problem

A first-year student stops logging into the online classroom and misses two classes. Nobody notices until it is too late. The agent should notice first, warn the student's advisor, send the student a warm check-in, offer an advising meeting, and hand off to a real person if the student mentions something serious.

## What success looks like (demo)

| # | Criterion | How we measure it | Met? |
|---|---|---|---|
| 1 | The "Jordan" scenario fires an alert with no one typing anything | Nightly score → score 7 ≥ limit 6 → alert, advisor task, check-in sent | |
| 2 | Contacts only the student and assigned advisor (plus the two written exceptions) | Outreach log + Testing Center NEVER-rule tests all refused | |
| 3 | No FERPA data shown before identity is confirmed | Testing Center trick-attempt batch passes | |
| 4 | Crisis language always reaches the counseling center | Testing Center crisis tests (obvious, indirect, false alarm) | |
| 5 | Student can book a meeting from offered times | Booking creates a `ServiceAppointment` with the assigned advisor | |

## Explicitly out of scope (v1)

- A real classroom system (Canvas, Moodle, etc.) — simulated. See ADR-004.
- Predictive risk model / Data Cloud — rule-based score in core Salesforce. See ADR-003.
- Contacting parents, instructors or anyone the student names. See ADR-001.
- Auto-booking meetings. See ADR-002.

## Constraints

| Constraint | Detail |
|---|---|
| Technical | Demo org is a Developer Edition with no Data Cloud. SMS, portal site and Slack still to be checked (SCA-2). |
| Compliance | FERPA: identity confirmed before grades, progress or assignments. Trust Layer masking and audit trail. |
| Tone | Warm and plain; no jargon, no blame. |

## Open questions

| Question | Blocking? | Owner | Raised |
|---|---|---|---|
| Are Einstein Generative AI, an Experience Cloud site, SMS messaging and Slack available in the org? | Yes, for channels | Build session (SCA-2) | 2026-11-06 |
| Is the ready-made Course Search agent available in the org? | No (fallback exists) | Build session (SCA-39) | 2026-11-06 |
| Add a Story Points field to Jira SCA? | No | Andrew Purpura | 2026-11-06 |

## 2026-11-19 — Agent Build (continued)

- Deliver a demo-ready build of the Student Concern Agent, not yet production-ready; student agent, portal, booking and degree progress are out of scope for this merge review

_Added automatically by Orchestrate when the turn finished._

## 2026-11-19 — Test the Agent created for Student Concern

- Produce a builder fix plan covering the 13 findings, ordered from a verified baseline through to optional tester tooling, for the builder to work from.
- Produce a complete Playwright QA script the person can hand to a browser agent, to test the application after the builder's fixes, with the person running the UAT himself.
- Keep the QA agent report-only: it must not fix anything, and must mark unverifiable selectors or behaviour as NOT VERIFIED rather than guess.

_Added automatically by Orchestrate when the turn finished._

## 2026-11-19 — Second Pass Fixes before QA

- Let the Playwright QA test alerts and own-students-only sharing as a non-admin advisor

_Added automatically by Orchestrate when the turn finished._

## 2026-11-19 — Second Pass Fixes before QA

- Get the UAT advisor test users able to run the tester form and the agent summary as non-admin users

_Added automatically by Orchestrate when the turn finished._

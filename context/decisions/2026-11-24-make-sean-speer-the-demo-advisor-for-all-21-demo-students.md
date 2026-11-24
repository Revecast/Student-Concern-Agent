# ADR-033 — Make Sean Speer the demo advisor for all 21 demo students

**Date:** 2026-11-24 · **Status:** Accepted
**Deciders:** Sean Speer · **Supersedes:** none

## Context

The agent only discusses a student with that student's assigned advisor, and the nightly alert goes to that advisor. Ernie was assigned to all 21 demo students, so Sean would see an empty bell and 'not on your caseload' responses.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Make Sean the demo advisor** | The agent and the alert bell work when Sean logs in as himself; no need to log in as someone else during the demo. | Ernie loses his own advisor assignments on the demo students until the demo is over. |
| **B — Sean uses 'Log in as' Ernie** | No change to advisor assignments. | Presenting as another person is awkward and can be confusing in front of an audience. |
| **C — Sean uses UAT Advisor One** | No change to Ernie's assignments. | UAT Advisor One is on only 2 students, so the demo would not cover the full set. |
| **D — Guide only, decide later** | Defers the change. | Leaves Sean unable to demo the agent. |

## Decision

Sean Speer is the assigned advisor (case team and account team) for all 21 demo students, and Ernie is removed from them. The UAT advisors are kept on their own students.

## Why

Sean is the presenter and needs the agent and alerts to work when he logs in as himself.

## Consequences

**Accepted costs:**
- Ernie no longer sees the demo students in his own advisor view.
- Two students (Avery Chen, Morgan Silva) have Sean ahead of UAT Advisor One in the team order, so Sean receives their alerts.

**What this forecloses:**
- Using Ernie's login as the presenter account for the demo.

**Revisit if:**
The demo is over, or Ernie needs the advisor assignments back for QA.

---

_Recorded automatically by Orchestrate when turn 3 of the session “Testing” finished, from the person’s answers to Orchestrate’s questions. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"c165da1c-da47-4e79-ad6b-bcd408866a98","turn":3,"from":"answer"} -->

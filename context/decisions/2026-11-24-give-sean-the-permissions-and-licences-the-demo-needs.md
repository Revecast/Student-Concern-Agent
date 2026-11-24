# ADR-034 — Give Sean the permissions and licences the demo needs

**Date:** 2026-11-24 · **Status:** Accepted
**Deciders:** Sean Speer · **Supersedes:** none

## Context

Sean is a System Administrator with the Student Concern Administrator group but lacked the Education Cloud, Prompt Template and Agentforce access that the AI features require.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Assign all three** | Matches what the UAT advisors who passed QA have. | Uses three more licence seats. |
| **B — Only Education Cloud and Prompt Template** | Skips the Agentforce licence. | The Agentforce panel may not open for Sean; not verified. |
| **C — Change nothing** | No changes to the org. | The AI features would not run for Sean. |

## Decision

Assign Sean Education Cloud Full Access, Prompt Template User and Manager (with Einstein Prompt Templates licence), and Agentforce user access (with Agentforce Default licence).

## Why

The demo needs these for the AI features to run for the presenter.

## Consequences

**Accepted costs:**
- Uses 3 of the available Agentforce licence seats and 6 of 10 Education Cloud seats.

**What this forecloses:**
- None recorded.

**Revisit if:**
Access to the Agentforce panel for Sean is not confirmed in a test run.

---

_Recorded automatically by Orchestrate when turn 3 of the session “Testing” finished, from the person’s answers to Orchestrate’s questions. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"c165da1c-da47-4e79-ad6b-bcd408866a98","turn":3,"from":"answer"} -->

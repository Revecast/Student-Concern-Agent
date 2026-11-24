# ADR-036 — Demo for Sean Speer runs on the existing Student Concern setup without the crisis-notice tester

**Date:** 2026-11-24 · **Status:** Accepted
**Deciders:** Andrew Purpura · **Supersedes:** none

## Context

Andrew asked for Sean Speer, an AE, to demo the concern agent with the permissions he needs. Sean's flow access covers the advisor agent flows but not the crisis-notice tester flow. The person was asked whether to give Sean the existing tester permission set or leave the tester out.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Give Sean the SYS – UAT Tester permission set** | Lets the crisis-notice step be shown in the demo | A one-record change in the dev org that grants access beyond the advisor agent flows |
| **B — Leave the tester out of the demo** | No extra access granted; the agent and alert demo still work | The crisis-notice step cannot be shown to Sean |

## Decision

Decision pending: the person has not yet chosen between giving Sean the tester permission set and leaving the crisis-notice tester out of the demo. The demo data check is also still unresolved.

## Why

Not yet given. The person asked for a thorough demo guide and was offered these two next steps.

## Consequences

**Accepted costs:**
- None recorded.

**What this forecloses:**
- None recorded.

**Revisit if:**
Andrew chooses one of the two next steps, or the demo data check is rerun and shows which students are flagged.

---

_Recorded automatically by Orchestrate when turn 2 of the session “Sean Testing Procedures” finished, from what was agreed in the conversation. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"33643920-3900-4edf-951d-0cb90f93cbc9","turn":2,"from":"conversation"} -->

# ADR-021 — Require the Run Flows access flag on UAT and advisor flows so Flow Access grants take effect

**Date:** 2026-11-19 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

QA case S6-1 failed: UAT Advisor One got 'Insufficient Privileges' on the tester flow and the agent wrongly said Avery Chen was not on her caseload. The cause was that the isAdditionalPermissionRequiredToRun setting was unset on the flows, so the Flow Access grants in the existing permission sets were ignored and the UAT users had no Run Flows permission.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Set isAdditionalPermissionRequiredToRun to true on the flows and keep the existing permission set grants** | Uses the grants already designed; no broad Run Flows permission is given to users | Requires checking every flow the agent and tester call, and the flag applies to Apex calls too, so tests must be updated |
| **B — Add Run Flows to the permission sets** | Quick to apply | Grants far more access than needed and bypasses the per-flow design |

## Decision

Turn on the additional-permission setting for the tester flow and the other agent flows used by the advisor agent and tester, and do not add Run Flows to any permission set. The automation alert flow keeps the setting off on purpose so it runs regardless of who saves the record.

## Why

Ernie asked for the existing per-flow permission set grant to take effect, and for no Run Flows permission to be added.

## Consequences

**Accepted costs:**
- Tests that run as users without the grant must be updated, and new refusal tests added
- Every new flow called by the agent needs the setting checked

**What this forecloses:**
- Granting Run Flows through permission sets

**Revisit if:**
A new flow is called by an agent or tester user and fails with Insufficient Privileges

---

_Recorded automatically by Orchestrate when turn 13 of the session “Second Pass Fixes before QA” finished, from the person’s answers to Orchestrate’s questions. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"20b980b8-1be2-4706-be68-d85ccb05103a","turn":13,"from":"answer"} -->

# ADR-015 — Decline the bulk Apex reset of Skyler's risk fields; leave the change to Ernie

**Date:** 2026-11-19 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

After the SCA-13 live check, Orchestrate proposed a script to reset one demo student's risk score and last-alerted date. The safety check flagged it as a bulk change needing approval.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Approve the one-off reset script** | Restores the demo student to her prior state immediately | A bulk change in the org that Ernie had not approved |
| **B — Decline; the change is not made by this route or any other** | Keeps the approval gate intact and leaves control with Ernie | Skyler's record keeps the live-check values until Ernie acts or the nightly scorer runs |

## Decision

Declined. Orchestrate must not run the reset script or make the same change any other way. Ernie decides whether to leave Skyler as she is or reset her himself in Salesforce.

## Why

Ernie declined the approval request; the reset is a data change he did not authorise.

## Consequences

**Accepted costs:**
- Skyler's score stays raised until the nightly scorer overwrites it at 5:00 AM Eastern
- Her last-alerted date stays set, so she will not trigger another alert for 7 days

**What this forecloses:**
- Resetting the demo record through an Orchestrate-run script in this session

**Revisit if:**
Ernie asks for the reset to be done, or chooses to do it himself and asks Orchestrate to confirm the result.

---

_Recorded automatically by Orchestrate when turn 4 of the session “Agent Build” finished, from the person’s answers to Orchestrate’s questions. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"78fef3c4-ef3b-4153-b3e9-9f1040d2ab70","turn":4,"from":"answer"} -->

# ADR-031 — Blank the score of UAT No-Advisor Student instead of leaving it at 7

**Date:** 2026-11-21 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

UAT No-Advisor Student sat at score 7 with a blank reason, which would confuse the demo and S2-9 testing.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Blank its score** | Clears the inconsistent state | Must be reset to 7 before any UAT run of S2-9 |
| **B — Leave it at 7** | No change needed for S2-9 runs | Score 7 with no reason is inconsistent |

## Decision

Clear the risk score of UAT No-Advisor Student.

## Why

Ernie chose the recommended option.

## Consequences

**Accepted costs:**
- Set back to 7 before any S2-9 UAT run

**What this forecloses:**
- Keeping the score at 7 during the demo

**Revisit if:**
S2-9 UAT is run

---

_Recorded automatically by Orchestrate when turn 13 of the session “Fixes from UAT round 2” finished, from the person’s answers to Orchestrate’s questions. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"403e781d-73e9-4eba-a271-10fac14dc939","turn":13,"from":"answer"} -->

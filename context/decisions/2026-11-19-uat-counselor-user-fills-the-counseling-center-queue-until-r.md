# ADR-019 — UAT Counselor user fills the Counseling Center queue until real crisis contacts arrive

**Date:** 2026-11-19 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

The Counseling Center queue needed a member for testing before the real crisis contacts were known.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — UAT Counselor user** | Recommended; keeps Ernie out of the queue | Not a real counsellor |
| **B — Ernie** | Simple | Ernie would receive test crisis alerts |

## Decision

The UAT Counselor user is the Counseling Center queue member until real crisis contacts are supplied.

## Why

Recommended option chosen by Ernie.

## Consequences

**Accepted costs:**
- Crisis routing has not been tested with a real counsellor

**What this forecloses:**
- Ernie as the queue member during testing

**Revisit if:**
Real crisis contacts are provided.

---

_Recorded automatically by Orchestrate when turn 3 of the session “Second Pass Fixes before QA” finished, from the person’s answers to Orchestrate’s questions. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"20b980b8-1be2-4706-be68-d85ccb05103a","turn":3,"from":"answer"} -->

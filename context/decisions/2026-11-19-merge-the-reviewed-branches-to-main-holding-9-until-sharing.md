# ADR-016 — Merge the reviewed branches to main, holding #9 until sharing change is signed off

**Date:** 2026-11-19 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

Ernie asked for a whole-project review to decide whether the work is ready to merge. The review found no blocker for the demo but flagged the Private org-wide sharing change in #9 and unverified coverage.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Merge everything now** | Fastest path to a complete demo build | Includes the org-wide sharing change without deliberate review |
| **B — Merge #1 to #8 and #10 to #18 after checks; hold #9 until signed off** | Keeps the risky sharing change deliberate while unblocking the rest | Requires running validate and reading coverage first |

## Decision

Merge #1 to #8 and #10 to #18 once the checks are done, in number order. Hold #9 until Ernie has signed off on the sharing change. Run a full RunLocalTests validate before any sandbox or production deploy.

## Why

Ernie asked whether the work is ready to merge; the review found it sound for the demo but not production-ready, with the sharing change needing a deliberate decision.

## Consequences

**Accepted costs:**
- Org-wide coverage must be re-verified before deploy
- #9 is delayed until sign-off

**What this forecloses:**
- Merging #9 as part of the batch without sign-off

**Revisit if:**
Coverage validate shows a deploy-blocking gap, or Ernie signs off on #9

---

_Recorded automatically by Orchestrate when turn 1 of the session “Agent Build (continued)” finished, from what was agreed in the conversation. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"83a1bd62-223b-5961-abb2-a4b8d0b601b2","turn":1,"from":"conversation"} -->

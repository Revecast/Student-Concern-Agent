# ADR-023 — Build the crisis fix, handoff fix and related fixes as one PR stacked on #24

**Date:** 2026-11-20 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

QA run found failures: the advisor agent refused a self-harm message without pointing to help, and the Handoff Summary invented student conversation. Several alert and template fixes were also needed.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Proceed with all 5 fixes** | Fixes every QA item found in this run and gets the demo ready in one reviewed PR | Larger change set to review at once |
| **B — Only fixes 1 and 2 (the big ones)** | Smaller change set and faster to ship | Leaves the smaller QA findings unfixed for later |

## Decision

Proceed with all 5 fixes on branch fix/SCA-22-qa-fixes, stacked on #24, deployed to jaxedupde-dev-ed with tests, and opened as PR #25.

## Why

Ernie approved the full fix plan after the QA run.

## Consequences

**Accepted costs:**
- PR #25 depends on #24 and cannot merge until it is merged

**What this forecloses:**
- Deferring the smaller QA findings to a later change

**Revisit if:**
Nothing recorded.

---

_Recorded automatically by Orchestrate when turn 2 of the session “UAT Fixes” finished, from the person’s answers to Orchestrate’s questions. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"cb826f7a-fe33-4621-88ac-a0506177c6da","turn":2,"from":"answer"} -->

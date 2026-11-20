# ADR-018 — Turn on Einstein Trust Layer PII masking in the dev org

**Date:** 2026-11-19 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

A check found PII masking off in the dev org.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Turn it on** | Recommended; masks personal data as intended | Changes org behaviour |
| **B — Report only** | No change to the org | Leaves masking off |

## Decision

Turn on Einstein Trust Layer PII masking.

## Why

Recommended option chosen by Ernie.

## Consequences

**Accepted costs:**
- None recorded.

**What this forecloses:**
- Leaving PII masking off in the dev org

**Revisit if:**
Testing shows masking breaks a required flow.

---

_Recorded automatically by Orchestrate when turn 3 of the session “Second Pass Fixes before QA” finished, from the person’s answers to Orchestrate’s questions. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"20b980b8-1be2-4706-be68-d85ccb05103a","turn":3,"from":"answer"} -->

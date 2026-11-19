# ADR-009 — Confirm the 11-18 design-session answers are saved as decisions for future sessions

**Date:** 2026-11-18 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

Ernie asked why the repo has nothing for the design to build on, and whether the original Agentforce build session answers can be reused.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Reuse the original intake answers as they are** | Most already match saved ADRs; avoids re-asking | One answer (when the advisor is alerted) conflicts with the current design |
| **B — Keep the design only in project memory and Jira** | Loads into every new session | Not visible in the repo and the side branch was never merged |

## Decision

The original 11-06 intake answers are reusable as they stand, except the advisor-alert timing, which Ernie still has to decide before SCA-13. The design lives in project memory and Jira; the repo stays as the template until the first feature branch lands.

## Why

The repo was never meant to hold code yet; the 11-06 session was design only, and the saved decisions cover nearly all original answers.

## Consequences

**Accepted costs:**
- The ADRs remain on an unmerged side branch until a pull request is opened
- This week's decisions (ADR-006 to 008) exist only in project memory

**What this forecloses:**
- None recorded.

**Revisit if:**
When the advisor-alert timing is decided, or when a pull request is opened to bring the context into main.

---

_Recorded automatically by Orchestrate when turn 3 finished, from what was agreed in the conversation. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"e51ed912-c917-454d-90dc-10010b081fbd","turn":3,"from":"conversation"} -->

# ADR-011 — Use a regular Build session instead of Agentforce Build

**Date:** 2026-11-18 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

The person asked why an Agentforce Build session needs all answers re-entered when project memory already holds the agent design.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Agentforce Build session** | Purpose-built for agent work | Requires re-entering answers already documented; unconfirmed whether it loads extra agent-specific tools |
| **B — Regular Build session** | Loads project memory (ADR-001 to 008, goals, environment, session records) and Jira SCA-1 to SCA-45 without re-entry; agent CLI commands and metadata deploy normally | Not confirmed whether Build lacks any tool specific to agents; would be revisited if a story shows an error |

## Decision

Build the agent in a regular Build session, using project memory and Jira for the design answers, starting with SCA-2 on branch feature/SCA-2-prerequisites in org Jax Edu PDE (jaxedupde-dev-ed).

## Why

The person pointed out the design answers are already documented and accessible, so re-entering them in Agentforce Build is unnecessary.

## Consequences

**Accepted costs:**
- Possible missing agent-specific tools in Build, to be handled story by story if they appear

**What this forecloses:**
- Using Agentforce Build as the default for this project unless a specific story requires it

**Revisit if:**
A build story fails because a tool needed for agent work is missing from a regular Build session.

---

_Recorded automatically by Orchestrate when turn 5 finished, from the person’s answers to Orchestrate’s questions. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"e51ed912-c917-454d-90dc-10010b081fbd","turn":5,"from":"answer"} -->

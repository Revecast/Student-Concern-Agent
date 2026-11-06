# ADR-004 — The classroom system (LMS) is fully simulated for the demo

**Date:** 2026-11-06 · **Status:** Accepted
**Deciders:** Andrew Purpura · **Supersedes:** none

## Context

The demo org has no classroom-system connection (no named credentials, connected apps or LMS package). Andrew could not sign up for a Canvas account.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Fully simulated (chosen)** | No outside accounts or hosting; demo fires on cue | Not "live" |
| **B — Canvas + hosted community MCP server** | Recognizable to higher-ed audiences | Needs a Canvas account with API tokens and a hosted MCP server; community code needs security review |
| **C — Moodle + its own MCP plugin** | Official plugin, no extra hosting | Must run a self-hosted Moodle |

## Decision

- **Risk score data:** a simulated classroom-activity object (student, course, last login, current grade, grade two weeks ago) filled by a load script — the "Jordan" scenario plus about 20 other students, with attendance entries.
- **Live assignments:** the agent calls one fixed tool, `get_live_assignments(student)`, which returns sample data.

## Consequences

**Accepted costs:** the demo shows no real LMS integration.
**What this forecloses:** nothing. A real Canvas or Moodle can sit behind `get_live_assignments` later without changing the agent.
**Revisit if:** a client engagement names its LMS, or a Canvas account with API access becomes available.

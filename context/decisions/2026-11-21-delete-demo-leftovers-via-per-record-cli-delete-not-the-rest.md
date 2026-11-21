# ADR-029 — Delete demo leftovers via per-record CLI delete, not the REST request body

**Date:** 2026-11-21 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

The approved REST DELETE call through sf api request failed with a body-format error in CLI 2.151.7, so the reset script cannot delete through that route.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Keep fixing the sf api request DELETE call** | Stays with the current script structure | Already failed twice; the CLI refuses the body format regardless of fixes |
| **B — Delete each record with sf data delete record** | Standard CLI command with no request body; deletes only the exported records | Slower, about 2 to 3 minutes for 33 calls |

## Decision

Orchestrate will change the demo reset script to delete each exported record with sf data delete record, after testing it on one made-up ID. Orchestrate asked for the go-ahead before editing the script and rerunning the rehearsal, which deletes the 33 approved records.

## Why

The approved REST route cannot be made to work in this CLI version, and the per-record command is simple and still limited to the exported list.

## Consequences

**Accepted costs:**
- Rehearsal takes a few minutes longer
- Another approval step before the real deletes

**What this forecloses:**
- Deleting through sf api request DELETE in this CLI version

**Revisit if:**
A later CLI version accepts DELETE request bodies through sf api request

---

_Recorded automatically by Orchestrate when turn 10 of the session “Fixes from UAT round 2” finished, from what was agreed in the conversation. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"403e781d-73e9-4eba-a271-10fac14dc939","turn":10,"from":"conversation"} -->

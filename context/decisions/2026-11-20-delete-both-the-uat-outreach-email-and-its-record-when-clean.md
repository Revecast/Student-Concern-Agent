# ADR-027 — Delete both the UAT outreach email and its record when cleaning up test data

**Date:** 2026-11-20 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

During cleanup of test outreach, OUT-018158 logged a 'UAT test' email sent to UAT Advisor One rather than to Avery, and its email record was not to Avery at all.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Delete both** | Removes the test email and its log row together, leaving no orphaned test records. | Removes the sent-email record itself, so the history of that test send is gone. |
| **B — Delete the row only** | Keeps the email record as evidence of the test send. | Leaves a test email on the record that is not tied to any outreach log. |
| **C — Delete neither** | Nothing is removed, so nothing can be lost by mistake. | Test data stays in the org and the cleanup stays incomplete. |

## Decision

When the cleanup runs, delete both OUT-018158 and its email record 02siw000001uXIUAA2.

## Why

Ernie chose the recommended option: delete both.

## Consequences

**Accepted costs:**
- The test send history for that email is no longer kept in the org.

**What this forecloses:**
- Keeping the UAT email record as evidence of the test send.

**Revisit if:**
QA needs the sent-email history of the UAT test for an audit.

---

_Recorded automatically by Orchestrate when turn 4 of the session “Fixes from UAT round 2” finished, from the person’s answers to Orchestrate’s questions. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"403e781d-73e9-4eba-a271-10fac14dc939","turn":4,"from":"answer"} -->

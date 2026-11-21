# ADR-030 — Delete the 220 bulk-test students permanently, with backup kept

**Date:** 2026-11-21 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context

Bulk-test students (98 at score 6 or more, owned by Ernie) would have been visible during the demo.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Delete them** | Removes them from sight entirely; backup and reload script preserve them | Permanent after the 15-day Recycle Bin window |
| **B — Leave them, avoid views** | No data change | Relies on avoiding views during the demo; they stay visible in reports and lists |
| **C — Move ownership away** | Keeps the records | Still in the org and could still surface |

## Decision

Delete all 1,545 bulk-test records (students, attendance, activity, enrollments, account) after taking a full backup.

## Why

Ernie chose the recommended option so the demo org shows only the intended students.

## Consequences

**Accepted costs:**
- Records sit in the Recycle Bin for about 15 days, then are gone for good unless rebuilt from the backup or loader script

**What this forecloses:**
- Using the bulk-test students in the demo without rebuilding them

**Revisit if:**
The bulk data is needed again for load or performance testing

---

_Recorded automatically by Orchestrate when turn 13 of the session “Fixes from UAT round 2” finished, from the person’s answers to Orchestrate’s questions. Edit it freely: Orchestrate never rewrites a record a person has edited._
<!-- orchestrate:decision-capture {"session":"403e781d-73e9-4eba-a271-10fac14dc939","turn":13,"from":"answer"} -->

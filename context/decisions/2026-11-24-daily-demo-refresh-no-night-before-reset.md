# ADR-038 — Daily demo refresh replaces the night-before reset

**Date:** 2026-11-24 · **Status:** Accepted · **Deciders:** Andrew Purpura · **Supersedes:** the night-before reset step in ADR-035

## Context
Andrew: a manual reset the night before each demo is not acceptable; it must just happen, and Sean needs real alerts now to practise.

## Decision
Scheduled Apex job **Student Demo Daily Refresh** (`StudentDemoDailyRefresh`, cron `0 30 1 * * ?`, 01:30 Pacific, runs as Andrew), 30 minutes before the 02:00 scorer:
- re-dates demo attendance and last logins to keep each student's story relative to today;
- features Jordan every day plus one of Casey / Quinn / Taylor in turn (day 0 = 2026-11-24: Casey; 12/1 Quinn, 12/2 Taylor, 12/3 Casey). Sets their score back to yesterday's value (below 6) and clears Risk Last Alerted Date, so the real scorer and flows alert the presenter;
- deactivates earlier RecordAlerts and completes earlier open "Check in with" Tasks on demo students. Deletes nothing.
Only students whose sole advisor is Sean rotate (Avery, Morgan, Riley also have UAT advisors).

## Consequences
- Lowering a score by code is a demo-only exception; the alerting score is always written by the real scorer.
- Bell notices accumulate daily (no API to clear).
- Turn off after the event: Setup → Scheduled Jobs → delete the job.
- Deployed 0Afiw000001VLZ3CAO; first run 2026-11-24 14:03 PST alerted Sean for Jordan and Casey; `--check` 6/6. PR #27 (stacked on #26).

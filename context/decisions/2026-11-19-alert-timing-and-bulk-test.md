# ADR-014 — Advisor alerted at the same time as the student; bulk test data labelled and withdrawn

- **Status:** Accepted
- **Date:** 2026-11-19
- **Deciders:** Ernie Maldonado (Orchestrate recommended the bulk-test option at his request)

## Decision
1. On an upward crossing to 6+ points, the advisor alert, advisor task and student check-in all fire together (confirms ADR-005 / ADR-010; SCA-13 and SCA-14 unchanged).
   Orchestrate also suggested an optional one-time advisor reminder if the student has not replied after 2 days. **Not accepted yet**: it's a design change, noted on SCA-13 for a later decision, and not built.
2. SCA-9's 200+ students bulk proof uses about 220 synthetic students under one account named "DEMO - Bulk Test Students (safe to delete)". After the scorer run is verified, their term enrollments are set to Withdrawn so nightly runs skip them. Nothing is deleted.

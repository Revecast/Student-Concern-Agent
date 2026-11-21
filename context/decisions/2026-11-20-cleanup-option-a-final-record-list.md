# ADR-026 — Cleanup Option A: final record list (not yet run)

**Status:** Accepted · **Date:** 2026-11-20 · **Deciders:** Ernie Maldonado

## Decision
Cleanup Option A is approved but runs only when Ernie says "go", after QA's final pass. Before any change, export every listed record (all fields) and re-check the list against the org; stop and ask if it differs.

Answers given 2026-11-20:
1. OUT-018158 logs the "UAT test" email to UAT Advisor One, not Avery. Delete BOTH the row (a01iw000009vaO9AAI) and its email 02siw000001uXIUAA2.
2. Also delete the 4 completed "Email: UAT test" Tasks on Avery's timeline: 00Tiw000002806gEAA, 00Tiw00000283UHEAY, 00Tiw0000028FIUEA2, 00Tiw0000028DNEEA2.

## Final list
- Close Tasks (Completed): 00Tiw0000026ZLJEA2, 00Tiw0000028E9VEAU, 00Tiw0000027kOpEAI, 00Tiw0000028iIrEAI, 00Tiw0000026QukEAE, 00Tiw00000280zYEAQ
- Switch off alerts: 0qZiw00000013BxEAI (RA-0000004890), 0qZiw00000013dNEAQ (RA-0000006115), 0qZiw00000014CrEAI (RA-0000007341), 0qZiw00000013DZEAY (RA-0000004891), 0qZiw00000013ezEAA (RA-0000006116)
- Delete emails: 02siw000001uPXtAAM, 02siw000001uRzSAAU, 02siw000001udfdAAA, 02siw000001ub5yAAA, 02siw000001uXIUAA2
- Delete email Tasks: 00Tiw000002806gEAA, 00Tiw00000283UHEAY, 00Tiw0000028FIUEA2, 00Tiw0000028DNEEA2
- Delete outreach rows: OUT-018157 a01iw000009vHF8AAM, OUT-018158 a01iw000009vaO9AAI, OUT-018160 a01iw000009vHDVAA2, OUT-018161 a01iw000009vjODAAY, OUT-018162 a01iw000009vd14AAA
- Leave open: RA-0000007342 (0qZiw00000014ETEAY), Task 00Tiw0000028jwTEAQ. Untouched: OUT-018159, all risk fields, Jordan Rivera, Skyler Adeyemi, all other students.

## Consequences
25 records: 11 changed (6 Tasks closed, 5 alerts off), 14 deleted (5 emails, 4 email Tasks, 5 outreach rows). Deleted records can only come back from the Recycle Bin (15 days) or the export.

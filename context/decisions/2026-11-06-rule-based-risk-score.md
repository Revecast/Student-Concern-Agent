# ADR-003 — Version 1 uses a rule-based risk score, computed nightly in core Salesforce

**Date:** 2026-11-06 · **Status:** Accepted
**Deciders:** Andrew Purpura · **Supersedes:** none

## Context

The design originally put the risk score in Data 360. Data Cloud is not set up in the demo org (Jax Edu PDE, Developer Edition), and advisors need to be able to explain why a student was flagged.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Rule-based points (chosen)** | Explainable; runs in core Salesforce now | Less nuanced |
| **B — Predictive model (Einstein / Data 360)** | Can find patterns | Needs historical outcome data and Data Cloud; hard to explain |

## Decision

A nightly scheduled Flow scores every first-year student:

| Signal | Points |
|---|---|
| Each missed class in the last 14 days (`AttendanceEntry`) | 2 each, up to 6 |
| Days since last classroom-system login: 5–9 / 10 or more | 3 / 5 |
| Current grade below C in any course | 3 |
| Grade dropped a letter in the last 2 weeks | 2 |
| **Alert limit** | **6 or more** |

- Points and the limit live in custom metadata, so they change without a deploy.
- The score and a plain-language reason (e.g. "missed 2 classes, no login in 5 days") are saved on the student record.
- The alert fires only when the score crosses the limit going up, at most once every 7 days per student.
- Demo scenario "Jordan": 2 missed classes (4) + 5 days no login (3) = 7, so the alert fires.

## Consequences

**What this forecloses:** nothing permanent. The same rules can move into Data Cloud later unchanged.
**Revisit if:** Data Cloud is provisioned and historical outcome data exists.

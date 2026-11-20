# ADR-025 — Sharing change in PR #9 signed off for merging to main (not for production)

**Date:** 2026-11-20 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none (completes the hold in ADR-016)

## Context

ADR-016 held PR #9 (SCA-5 part 2: Account, Case and Opportunity Private org-wide; advisors see only their own students through the account team, ADR-013) until the sharing change was signed off. QA Suite 3 (advisors see only their own students) passed when run as the UAT users on 2026-11-20.

## Decision

Ernie signs off on the sharing change in #9 for merging to `main`. #9, and the PRs after it, may be merged in number order.

## Why

The change is already live in the dev org and QA Suite 3 passed as the real non-admin UAT users.

## Consequences

**This is not a production sign-off.** The full RunLocalTests validate before any sandbox or production deploy still stands (ADR-016). Sharing (OWD) changes recalculate access org-wide, so a production deploy needs its own review and timing.

**Revisit if:** a sandbox or production validate fails on sharing, or QA Suite 3 fails on a later pass.

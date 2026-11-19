# ADR-002 — Offer meeting times; the student picks. No auto-booking.

**Date:** 2026-11-06 · **Status:** Accepted
**Deciders:** Andrew Purpura · **Supersedes:** none

## Context

The story says the agent "books an advising meeting". Booking without the student's choice risks no-shows and feels pushy, which conflicts with the warm, plain tone.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Offer 3 slots, student picks (chosen)** | Student is in control; fewer no-shows | One extra step |
| **B — Auto-book, student can move it** | Faster | Books meetings students never wanted; fills advisor calendars |

## Decision

The check-in message offers 3 open slots with the student's assigned advisor (Salesforce Scheduling: `ServiceAppointment`, `WorkType`). The meeting is booked only when the student picks one. The slot is rechecked at booking time; if it was taken, the agent offers fresh times rather than failing.

## Consequences

**Revisit if:** demo or real data shows students ignore the offer and an auto-book with easy cancel works better.

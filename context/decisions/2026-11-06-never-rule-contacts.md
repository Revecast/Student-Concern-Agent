# ADR-001 — The agent contacts only the student and their assigned advisor, with two written exceptions

**Date:** 2026-11-06 · **Status:** Accepted
**Deciders:** Andrew Purpura · **Supersedes:** none

## Context

The intake's NEVER rule says the agent contacts no one but the student and the advisor. The story also sends crises to the counseling center and human handoffs through Omni-Channel, both of which reach other people.

## Options considered

| Option | For | Against |
|---|---|---|
| **A — Allow crisis + advising queue (chosen)** | Keeps the safety path and covers an unavailable advisor | Two exceptions to test and log |
| **B — Crisis exception only** | Tighter rule | Handoff fails when the assigned advisor is away |
| **C — No exceptions** | Strictest | A student in crisis only gets a phone number, no warm handoff |

## Decision

The agent contacts only the student and their assigned advisor (looked up through `SuccessTeam`). Two exceptions:
1. **Counseling center**, when the student uses crisis language.
2. **Advising queue**, when the assigned advisor is unavailable for a requested handoff.

It never contacts parents, instructors or anyone the student names.

## How it is enforced (design)

- The messaging action has **no recipient input**. It can only reach the student's own contact details or the assigned advisor.
- The crisis check runs on a fixed keyword list **before** the model sees the message, with model judgment as a backup. On a match: stop other topics, share 988 and campus counseling, warm handoff.
- Every outreach row in `Student_Outreach__c` records which exception, if any, was used.
- Every Jira story touching messaging, crisis or the queue carries the `never-rule` label and repeats the rule in its acceptance criteria.

## Consequences

**Accepted costs:** two exception paths must be tested in the Testing Center batch.
**What this forecloses:** any "notify instructor" or "notify parent" feature.
**Revisit if:** the school's policy requires instructor or guardian notification.

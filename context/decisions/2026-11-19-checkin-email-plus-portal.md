# ADR-008: First check-in by school email, replies in portal chat (if no SMS)

**Status:** Accepted · **Date:** 2026-11-19 · **Deciders:** the person running the build session (Delivery)

## Context
SMS messaging is unlikely to be available in the Developer Edition demo org (confirm in SCA-2). A portal chat cannot start a conversation on its own.

## Decision
If SMS is not available, the warm check-in (SCA-15) goes to the student's school email with the three offered meeting times (ADR-002) and a link to the portal. The student replies and books in portal chat with the student agent. The email goes only to the student's own school email (ADR-001).

If SCA-2 finds SMS is available, SMS can be added later; this decision does not change.

## Consequences
SCA-32 (portal/SMS channel) becomes portal first. The identity code (SCA-34) is still needed for anything sent outside the portal.

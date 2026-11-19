# ADR-013 — "Own students only": Account Private + advisor on the account team

- **Status:** Accepted
- **Date:** 2026-11-19
- **Deciders:** Ernie Maldonado

## Context
SCA-5 requires advisors to see only their assigned students. Account org-wide default was Public Read/Write (Contact Controlled by Parent), so every user saw every student.

## Decision
Set Account (and therefore Contact) org-wide default to Private for internal users. The assigned advisor is added to the student's administrative account team with Read access, kept in step with the Advisee case team. No Apex.

## Consequences
- Org-wide change; reversible. The 4 current users are all admins, so nobody loses access.
- Changing an advisor means updating both the case team and the account team.

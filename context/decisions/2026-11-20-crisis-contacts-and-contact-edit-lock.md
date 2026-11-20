# ADR-022 — Advisor agent crisis guidance uses 911 + 988 + Counseling Center; contact edit lock deferred

**Date:** 2026-11-20 · **Status:** Accepted
**Deciders:** Ernie Maldonado · **Supersedes:** none

## Context
QA S6-11: the advisor agent refused "My student told me he wants to hurt himself". The real campus crisis list and phone number (open answer 9) are not known yet. QA also found that advisors can edit and delete student Contacts (Standard User profile + Education Cloud Access permission set), and that PRs #22 and #24 are stacked and not merged.

## Decision
1. The advisor agent's Crisis Support reply gives: 911 for immediate danger, call or text 988 (Suicide and Crisis Lifeline), and contact the campus Counseling Center now. No campus phone number until answer 9 arrives.
2. Advisor read-only access to student Contacts is deferred to its own change: Jira SCA-46. Access stays as it is for the demo.
3. PRs are not merged by Orchestrate. Ernie merges #1 to #25 in number order (ADR-016) once Andy grants him rights to change the repo settings; he may then ask Orchestrate to merge them all.

## Consequences
When answer 9 arrives, add the campus crisis number to the crisis_support subagent text.

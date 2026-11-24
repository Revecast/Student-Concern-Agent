# ADR-037 — Sean's demo: crisis tester in, Advising Queue path out, scripts name Sean

**Date:** 2026-11-24 · **Status:** Accepted · **Deciders:** Andrew Purpura (asked Orchestrate to decide) · **Supersedes:** ADR-036

## Decision
- Sean Speer gets SYS – UAT Tester (assignment 0Paiw000005ZTneCAG, verified) so he can show the crisis hand-off.
- Sean is not added to the Advising Queue; the no-advisor path is left out of the demo.
- demo-reset.py, load-demo-data.apex and add-advising-queue-member.apex now use `sean.speer@jaxconsult.com.edudemopde` (PR #26, stacked on #25). With Ernie's name a reset would re-add Ernie to every team and `--check` could never pass for Sean.
- Andrew Purpura given DATA – Student Success – Read Only (0Paiw000005ZV7xCAG) so Orchestrate sessions, which connect as him, can read risk fields.

## Why
Andrew said he did not build this and asked Orchestrate to decide. The crisis step is the strongest safety point for a university audience; the queue path is an edge case.

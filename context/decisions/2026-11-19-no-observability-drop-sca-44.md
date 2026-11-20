# ADR-007: No observability work — drop SCA-44 only

**Status:** Accepted · **Date:** 2026-11-19 · **Deciders:** the person running the build session (Delivery)

## Decision
Observability is out of scope. SCA-44 (monitoring report, dashboard and weekly review) will not be built.

Everything else in the Testing epic (SCA-41) stays: SCA-42 Testing Center batch, SCA-43 Trust Layer masking and audit evidence, SCA-45 runbook dry run. The `Student_Outreach__c` log (SCA-3, SCA-37) also stays, because it enforces the contact rule (ADR-001), not monitoring.

## Revisit if
The demo needs to show ongoing monitoring to a buyer.

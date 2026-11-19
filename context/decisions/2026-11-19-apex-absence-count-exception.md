# ADR-012 — Small Apex action counts absences for the nightly scorer (exception to ADR-005)

- **Status:** Accepted
- **Date:** 2026-11-19
- **Deciders:** Ernie Maldonado

## Context
The nightly scorer (SCA-9) is a scheduled Flow per ADR-005. In jaxedupde-dev-ed, Flow cannot use AttendanceEntry or AttendanceRecording ("Entity is not accessible: AttendanceEntry", API 66.0 and 62.0). SOQL from Apex works. Academic Operations is off; turning it on was not confirmed to help and may not be reversible.

## Decision
One bulk-safe invocable Apex action returns missed-class counts per student for the scoring window. Everything else (points, reason, alert limit, writing Risk_Score__c / Risk_Reason__c) stays in the scheduled Flow. The action is tested at 200+ records.

## Consequences
- ADR-005 stays the rule; this is the single named exception.
- The Apex class needs classAccesses on the agent/automation permission set.
- If Academic Operations is later enabled and Flow can read AttendanceEntry, the action can be replaced by a Get Records.

# Flow access for non-admin users (SCA-36 QA fix)

## Problem (QA second pass, 2026-11-19)

The four UAT users got "Insufficient Privileges" on SF – UAT Send Message Tester, and the advisor
agent told UAT Advisor One that Avery Chen was "not on your caseload" (QA case S6-1).

Cause: the flows had `isAdditionalPermissionRequiredToRun` unset. With it unset, a user needs the
**Run Flows** system permission, and the Flow Access grants in our permission sets are ignored.
None of the UAT users has Run Flows (profile, permission sets, group, Flow User box: all false).
The caseload logic itself was fine: run as UAT Advisor One it returns Avery Chen as assigned.

## Fix

`isAdditionalPermissionRequiredToRun = true` on the four flows the advisor agent and the tester call,
so each runs for users granted Flow Access to it. Run Flows was **not** added anywhere.

| Flow | Called by | Flow Access granted by |
|---|---|---|
| SF_UAT_Send_Message_Tester | Testers (screen flow) | SYS – UAT Tester |
| SUB_Find_My_Student | Advisor agent | APP – Student Success Advisor Agent |
| PF_Student_Risk_Grounding | Student Risk Summary template (agent) | APP – Student Success Advisor Agent (added) |
| SUB_Send_Student_Message | Tester; automations | SYS – UAT Tester, SYS – Student Concern Automation (added) |

SUB_Alert_Assigned_Advisor and the record-triggered / scheduled scoring flows are left unset on purpose:
they run in system context from automation and must not depend on who saved the record.

## Evidence

- Deploy 0Afiw000001Rpc9CAC to jaxedupde-dev-ed: Succeeded, 9 components, 45/45 tests.
- Read back from the org (2026-11-20): flag `true` on all four flows (active versions: tester v2,
  Find My Student v2, Send Student Message v2, Risk Grounding v5); unset on SUB_Alert_Assigned_Advisor.
- Read back: all four UAT users have Run Flows = false and Flow Access to all four flows.
- New tests: an advisor **without** the agent permission set is refused by SUB_Find_My_Student;
  a caller without the grant is refused by SUB_Send_Student_Message; a score crossing saved by a
  non-admin user (Run Flows asserted false) still creates the advisor alert.

## Still to confirm in the browser

Logging in as UAT Advisor One (tester form opens; agent summarizes Avery Chen) is QA cases S6-1 and the
tester suite in the Playwright QA script. Orchestrate does not hold the UAT passwords, so it proved
the same access with tests run as non-admin users, not with a live login.

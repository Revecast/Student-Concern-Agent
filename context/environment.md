# Environment — Student Concern Agent (Revecast demo)

> Orgs, sandboxes, endpoints and **credential references**. Never credential values.

**Last reviewed:** 2026-11-19

## Salesforce orgs

| Purpose | Alias | Type | My Domain / URL | Notes |
|---|---|---|---|---|
| Demo / build | jaxedupde-dev-ed | Developer Edition (API 68.0) | jaxedupde-dev-ed.develop.my.salesforce.com | Education Cloud data model present but empty. No Data Cloud. No named credentials or connected apps. Org time zone America/Los_Angeles; demo time zone America/New_York. |

## Connected systems

| System | Environment | How we authenticate | Credential reference |
|---|---|---|---|
| Classroom system (LMS) | Simulated | None — sample data | n/a (ADR-004) |
| Jira | revecast.atlassian.net, project SCA | Orchestrate connector | Orchestrate connection |
| GitHub | Revecast/Student-Concern-Agent | Orchestrate connector | Orchestrate connection |

## Project settings

- `sourceApiVersion` **66.0** (raised from 64.0 on 2026-11-19: Agent Script needs 65.0+). Every artifact is pinned to 66.0.
- Feature branch per story, `feature/SCA-<n>-<slug>`, PR to `main` (ADR-006).

## Prerequisites — checked 2026-11-19 (SCA-2)

Full table with evidence: [`docs/SCA-2-prerequisites.md`](../docs/SCA-2-prerequisites.md).

| Prerequisite | Status | Fallback |
|---|---|---|
| Einstein Generative AI | On | — |
| Agentforce | Licensed, off | Settings deploy at SCA-22 (reversible) |
| Agent Script | API 65.0+ only | sourceApiVersion raised to 66.0 |
| Experience Cloud portal | Not enabled | Enabling is permanent; go-ahead needed at SCA-32 |
| SMS | Not licensed | ADR-008 email check-in |
| Slack | Not connected | Waiting on answer 8 |
| Course Search Agent | Not present | Course-catalog topic (SCA-39) |
| Data Cloud | Not provisioned | Check Data Library at SCA-28 |
| Salesforce Scheduler | Not licensed | Flow slot finder over ServiceAppointment (SCA-27) |
| Omni-Channel | Off | Settings deploy at SCA-40 (reversible) |
| Education Cloud objects | Present, empty; user needs the Education Cloud Full Access permission | Demo data (SCA-8) |
| Advisor relationship | Case team on the student's Advisee Case (no SuccessTeamMember object) | Built in SCA-8 |

## Access we hold

- Ernie Maldonado (System Administrator) — assigned **Education Cloud Full Access** and **Prompt Template Manager** on 2026-11-19.

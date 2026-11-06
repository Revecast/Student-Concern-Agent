# Environment — Student Concern Agent (Revecast demo)

> Orgs, sandboxes, endpoints and **credential references**. Never credential values.

**Last reviewed:** 2026-11-06

## ⚠️ Never put secrets in this file

Record **where** a credential lives, never what it is:

- ✅ `Named Credential: Acme_ERP_Prod` · `LastPass: "Acme — ERP integration user"`
- ❌ a password, token, private key, session id, or connection string with credentials in it

## Salesforce orgs

| Purpose | Alias | Type | My Domain / URL | Notes |
|---|---|---|---|---|
| Demo / build | jaxedupde-dev-ed | Developer Edition | jaxedupde-dev-ed.develop.my.salesforce.com | Education Cloud student-success data model present. No Data Cloud. No named credentials or connected apps. |

## Connected systems

| System | Environment | How we authenticate | Credential reference |
|---|---|---|---|
| Classroom system (LMS) | Simulated | None — sample data | n/a (ADR-004) |
| Jira | revecast.atlassian.net, project SCA | Orchestrate connector | Orchestrate connection |
| GitHub | Revecast/Student-Concern-Agent, branch `main` | Orchestrate connector | Orchestrate connection |

## Prerequisites still to check (SCA-2)

- Einstein Generative AI / Agentforce turned on
- Experience Cloud site for the student portal
- SMS messaging add-on (Digital Engagement)
- Slack connection
- Ready-made Course Search agent

## Deployment path

> **Not yet filled in.** — Design only so far; no build yet.

## Orgs

- Jax Edu PDE (developer org): org profile kept by Orchestrate — on the Connectors page, and for owners and admins in Settings → Context → Environments. Sessions that use this org load it automatically. <!-- orchestrate:org-profile 00Diw000003p0quEAA -->

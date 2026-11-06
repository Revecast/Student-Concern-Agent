<!-- orchestrate:template-version: v1.0.0 -->
# Context — Revecast demo / Student Concern Agent

> **This file is the index.** It is loaded into every Orchestrate session on this repo, so it stays
> short — target 150 lines, hard ceiling 200. One line per entry pointing at the detail file. Put the
> detail in `context/`, not here.

**Last reviewed:** 2026-11-06 · **Maintained by:** the team working this engagement

---

## The one-paragraph version

An Agentforce demo for higher education. A nightly rule-based score spots first-year students whose attendance and classroom logins are dropping. When the score crosses the limit, a Flow alerts the assigned advisor and sends the student a warm check-in offering three meeting times. A student agent (portal + SMS) does the check-in, booking and tutoring questions; an advisor agent (Salesforce + Slack) summarizes the student and drafts outreach. FERPA identity checks, a crisis path to counseling, and a strict "student and assigned advisor only" contact rule are enforced in code. The classroom system is simulated. Status 2026-11-06: designed, backlog in Jira SCA (SCA-1 to SCA-45), nothing built.

---

## Where things are

| File | What lives there | Read it when |
|---|---|---|
| [`context/client.md`](context/client.md) | Who they are, org chart, decision makers | You need to know who to ask, or who signs off |
| [`context/environment.md`](context/environment.md) | Orgs, sandboxes, credential *references* | You are about to deploy or connect to something |
| [`context/goals.md`](context/goals.md) | What we are solving, success criteria, budget | You are scoping, estimating, or saying no to something |
| [`context/decisions/`](context/decisions/) | One dated ADR per architectural choice | You are about to relitigate a settled decision |
| [`context/history.md`](context/history.md) | Shipped / parked / abandoned, dated | You are wondering whether something already exists |
| [`context/handoff.md`](context/handoff.md) | Current state, in progress, next steps | **Start here** if you are picking this up cold |
| [`context/gotchas.md`](context/gotchas.md) | The things that will bite you | **Before** you assume something works the obvious way |

### Decisions (all 2026-11-06, Accepted)

- [ADR-001 NEVER rule: student + assigned advisor only, two exceptions](context/decisions/2026-11-06-never-rule-contacts.md)
- [ADR-002 Offer meeting times; student picks](context/decisions/2026-11-06-offer-times-not-auto-book.md)
- [ADR-003 Rule-based risk score, nightly, core Salesforce](context/decisions/2026-11-06-rule-based-risk-score.md)
- [ADR-004 Fully simulated classroom system](context/decisions/2026-11-06-fully-simulated-classroom-system.md)
- [ADR-005 Architecture: native patterns first](context/decisions/2026-11-06-architecture-native-patterns.md)

## Fast facts

| | |
|---|---|
| Primary Salesforce org | jaxedupde-dev-ed (Developer Edition, no Data Cloud) |
| Sandbox(es) | *see [`context/environment.md`](context/environment.md)* |
| Jira project | SCA — 9 epics, 36 stories, 113 pts (SCA-1 to SCA-45) |
| Delivery methodology | Jax: Launch · Define · Develop · Test · Release · Sustain |
| Repo | `Revecast/Student-Concern-Agent` |
| Default branch | `main` |
| First build story | SCA-2, prerequisites check |

## Current state

> **Start with [`context/handoff.md`](context/handoff.md).** It is rewritten at the end of every
> session; this index is not. If the two disagree, handoff.md is newer.

---

## Rules for this directory

1. **`CONTEXT.md` is required. Everything under `context/` is optional.**
   An empty `goals.md` is worse than no `goals.md` — it looks answered when it is not. Delete a file
   you have nothing to put in, or leave the `> **Not yet filled in.**` marker so it is visibly unfilled.
2. **Never put secrets in any of these files.** Reference the credential — the 1Password/LastPass entry,
   the Named Credential, the External Client App — never the value. A private repo is still a repo:
   it gets cloned, forked, backed up and shared.
3. **One ADR per decision, not one per meeting.** ADRs are for choices with tradeoffs someone might
   question later, not status updates. See [`context/decisions/README.md`](context/decisions/README.md).
4. **`handoff.md` gets rewritten at the end of every session.** If it is not, it rots within a week and
   the next person stops trusting it — which costs more than not having it.
5. **`gotchas.md` entries carry the incident.** "Cannot deploy Prompt Template content via Metadata API —
   silent no-op, must use Prompt Builder UI (hit 2026-09-10, cost 2 hrs)." The incident and the date are
   what stop the next person waving it away.
6. **Dated, not relative.** "Shipped 2026-04-12", never "shipped last spring". Someone will read this
   in 2027.

## How this connects to the wider picture

Patterns, standards and learnings that are **not specific to this client** do not belong here — they go
to Revecast's central ontology, where every future engagement can benefit from them. Client code and
client-identifying detail stay in this repo and never leave it.

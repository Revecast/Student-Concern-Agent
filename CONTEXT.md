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

<!-- orchestrate:auto-index -->
**Index** (kept by Orchestrate from what this memory holds; edit outside these markers):
- [`context/handoff.md`](context/handoff.md) — where things stand and what is next — start here
- [`context/goals.md`](context/goals.md) — goals, success criteria and scope
- [`context/client.md`](context/client.md) — who the client is and who decides
- [`context/environment.md`](context/environment.md) — orgs, sandboxes and connection references
- [`context/gotchas.md`](context/gotchas.md) — what will bite you
- [`context/history.md`](context/history.md) — shipped, parked and abandoned work
- [`context/sessions/README.md`](context/sessions/README.md) — one record per session: what each did, decided and left open
- Decisions in [`context/decisions/`](context/decisions/) (23, newest first):
  - [ADR-022 — Advisor agent crisis guidance uses 911 + 988 + Counseling Center; contact edit lock deferred](context/decisions/2026-11-20-crisis-contacts-and-contact-edit-lock.md)
  - [ADR-023 — Build the crisis fix, handoff fix and related fixes as one PR stacked on #24](context/decisions/2026-11-20-build-the-crisis-fix-handoff-fix-and-related-fixes-as-one-pr.md)
  - [ADR-017 — Use existing students for advisor testing, with UAT advisors on Avery and Morgan](context/decisions/2026-11-19-use-existing-students-for-advisor-testing-with-uat-advisors.md)
  - [ADR-019 — UAT Counselor user fills the Counseling Center queue until real crisis contacts arrive](context/decisions/2026-11-19-uat-counselor-user-fills-the-counseling-center-queue-until-r.md)
  - [ADR-018 — Turn on Einstein Trust Layer PII masking in the dev org](context/decisions/2026-11-19-turn-on-einstein-trust-layer-pii-masking-in-the-dev-org.md)
  - [ADR-020 — Prompt-injection detection on; PII masking deferred until Data Cloud](context/decisions/2026-11-19-trust-layer-injection-on-masking-blocked.md)
  - [ADR-013 — "Own students only": Account Private + advisor on the account team](context/decisions/2026-11-19-sharing-private-account-team.md)
  - [ADR-021 — Require the Run Flows access flag on UAT and advisor flows so Flow Access grants take effect](context/decisions/2026-11-19-require-the-run-flows-access-flag-on-uat-and-advisor-flows-s.md)
  - [ADR-007 — No observability work — drop SCA-44 only](context/decisions/2026-11-19-no-observability-drop-sca-44.md)
  - [ADR-016 — Merge the reviewed branches to main, holding #9 until sharing change is signed off](context/decisions/2026-11-19-merge-the-reviewed-branches-to-main-holding-9-until-sharing.md)
  - [ADR-006 — Feature branch per story](context/decisions/2026-11-19-feature-branch-per-story.md)
  - [ADR-015 — Decline the bulk Apex reset of Skyler's risk fields; leave the change to Ernie](context/decisions/2026-11-19-decline-the-bulk-apex-reset-of-skyler-s-risk-fields-leave-th.md)
  - [ADR-008 — First check-in by school email, replies in portal chat (if no SMS)](context/decisions/2026-11-19-checkin-email-plus-portal.md)
  - [ADR-012 — Small Apex action counts absences for the nightly scorer (exception to ADR-005)](context/decisions/2026-11-19-apex-absence-count-exception.md)
  - [ADR-014 — Advisor alerted at the same time as the student; bulk test data labelled and withdrawn](context/decisions/2026-11-19-alert-timing-and-bulk-test.md)
  - [ADR-011 — Use a regular Build session instead of Agentforce Build](context/decisions/2026-11-18-use-a-regular-build-session-instead-of-agentforce-build.md)
  - [ADR-009 — Confirm the 11-18 design-session answers are saved as decisions for future sessions](context/decisions/2026-11-18-confirm-the-11-18-design-session-answers-are-saved-as-decisi.md)
  - [ADR-010 — Alert the advisor at the same time as the student, not only after silence](context/decisions/2026-11-18-alert-the-advisor-at-the-same-time-as-the-student-not-only-a.md)
  - [ADR-003 — Version 1 uses a rule-based risk score, computed nightly in core Salesforce](context/decisions/2026-11-06-rule-based-risk-score.md)
  - [ADR-002 — Offer meeting times; the student picks. No auto-booking.](context/decisions/2026-11-06-offer-times-not-auto-book.md)
  - [ADR-001 — The agent contacts only the student and their assigned advisor, with two written exceptions](context/decisions/2026-11-06-never-rule-contacts.md)
  - [ADR-004 — The classroom system (LMS) is fully simulated for the demo](context/decisions/2026-11-06-fully-simulated-classroom-system.md)
  - [ADR-005 — Architecture choices for the Student Concern Agent (native patterns first)](context/decisions/2026-11-06-architecture-native-patterns.md)
<!-- /orchestrate:auto-index -->

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

# Gotchas

> The things that will bite the next person. **Append-only — this file only grows.**
> [`handoff.md`](handoff.md) is *now*; this is *forever*.

**Last reviewed:** 2026-11-06

## How to write one

**Every entry carries the incident and the date.** That is what stops the next person waving it away
and losing the same two hours.

> ❌ "Prompt Template deploys can be unreliable."
>
> ✅ "**Prompt Template content updates cannot be deployed via Metadata API** — the deploy reports
> success but the content is unchanged (silent no-op). Must be edited in Prompt Builder UI.
> *Hit 2026-09-10, cost ~2 hrs before we noticed the content had not changed.*"

The difference: the second one is checkable, tells you what to do instead, and carries the evidence
that it is real.

---

## Platform

<!-- Salesforce / platform behaviour that is surprising, undocumented, or documented-but-wrong. -->

-

## This client's environment

<!-- Specific to this org: a validation rule that fires unexpectedly, a managed package that
     conflicts, an integration that rate-limits, a sandbox that behaves unlike production. -->

-

## Process

<!-- How work gets approved, deployed or reviewed here that is not obvious — an approval that takes
     three days, a deploy window, a person who must be in the room. -->

-

## Recorded 2026-11-06

- **Jira SCA has no Story Points, Acceptance Criteria or Definition of Done fields.** All three are written into each ticket's description under headings, so points do not add up on boards or sprint reports. *Hit 2026-11-06 creating the 36-story backlog (SCA-1 to SCA-45, 113 pts).* Add a Story Points field to SCA, then fill it on all stories.
- **SMS is not proof of identity.** A phone number proves nothing (shared or reassigned phones). Over SMS, require a one-time code to the school email before showing any FERPA data. *Design decision 2026-11-06.*
- **Data Cloud is not provisioned in jaxedupde-dev-ed.** Anything planned for Data 360 runs in core Salesforce for now. *Found 2026-11-06 during design.*

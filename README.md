# {{PROJECT_NAME}}

Salesforce delivery repository for **{{CLIENT_NAME}}**, created from Revecast's baseline template.

## Start here

**[`CONTEXT.md`](CONTEXT.md)** — the index for everything about this engagement. If you are picking
this up cold, read that first, then [`context/handoff.md`](context/handoff.md).

```
CONTEXT.md              ← index, loaded into every Orchestrate session
context/
  client.md             ← who they are, who decides
  environment.md        ← orgs, sandboxes, credential references (never values)
  goals.md              ← problem, success criteria, constraints
  decisions/            ← one dated ADR per architectural choice, append-only
  history.md            ← shipped / parked / abandoned, dated
  handoff.md            ← current state — rewritten every session
  gotchas.md            ← what will bite you — append-only
force-app/              ← Salesforce metadata
config/                 ← scratch org definitions
```

## Why the context directory exists

Orchestrate reads `CONTEXT.md` and the files under `context/` at the start of every session on this
repo, and updates `handoff.md` at the end. The structure is uniform across every Jax engagement so
that context is in a known place rather than scattered across Slack, email and people's heads.

Two rules matter more than the rest:

- **Never put secrets in these files.** Reference the credential, never the value. A private repo is
  still cloned, forked and backed up.
- **`handoff.md` is rewritten every session; `gotchas.md` only ever grows.** Handoff is *now*.
  Gotchas is *forever*.

The full rules are at the bottom of [`CONTEXT.md`](CONTEXT.md).

## What stays here and what goes central

Client code and client-identifying detail **stay in this repo**. Patterns and learnings that are not
specific to this client go to Revecast's central ontology, so future engagements benefit. That is a
separate, deliberately narrower record — not a copy of what is here.

---

## For whoever maintains this template

### Placeholders

Filled in at materialisation. If you add one, add it here too or it ships literally.

| Placeholder | Becomes |
|---|---|
| `{{CLIENT_NAME}}` | Client / account name |
| `{{PROJECT_NAME}}` | Engagement or project name |
| `Student-Concern-Agent` | Repository short name (no owner) |
| `Revecast/Student-Concern-Agent` | `owner/repo` |
| `{{SF_ORG_ALIAS}}` | Primary Salesforce org alias |
| `2026-11-06` | Materialisation date, `YYYY-MM-DD` |

### The unfilled-file question

Andy's rule is *"no blank templates — an empty `goals.md` is worse than no `goals.md`."* That is right,
and it is in tension with a template repo, which ships every file by definition.

The resolution here: every unfilled section carries an explicit **`> **Not yet filled in.**`** marker
plus a comment saying what belongs there. So an unfilled file is *visibly* unfilled rather than looking
complete-but-empty — which is the actual failure Andy's rule is guarding against. Delete any file you
genuinely have nothing for; the marker is for files you intend to fill.

**This is a judgement call worth confirming.** The alternative is shipping only `CONTEXT.md` and letting
each file get created when it first has content.

### Pinning

Materialisation pins to a **tag**, never a moving branch. Tag after changes land (`v1.0.0`, `v1.1.0`),
or in-flight edits reach the next repo created from this template.

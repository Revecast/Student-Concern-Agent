# Merge runbook: PRs #1 to #25

Checked 2026-11-20 from the GitHub API: all 25 PRs open, none merged. `main` has no branch protection.
"Automatically delete head branches" is **off**, so GitHub will **not** move a PR to `main` for you when
the branch it targets is merged. You must change those bases by hand (step 3).

## 1. Which PRs target what

| PRs | Base (target) | Notes |
|---|---|---|
| #1 to #18 | `main` | Stacked: each branch contains every earlier one, so each diff shows earlier stories until those merge |
| #19, #20, #21, #22, #23 | `feature/SCA-22-advisor-agent` (the head of #18) | Second-pass fixes |
| #24 | `fix/SCA-36-uat-message-tester` (the head of #22) | Flow-access fix |
| #25 | `fix/SCA-36-flow-access` (the head of #24) | QA fixes, including UAT round 2 |

## 2. Rules for every merge

- Use **Create a merge commit**. Do not squash or rebase: the branches are stacked, and a squash
  rewrites the earlier commits so the next PR shows them again as new changes or conflicts.
- Merge strictly in number order. Before each one, open the PR's **Files changed** and check it shows
  only that story (earlier stories should have dropped out). If it still shows earlier work, stop: the
  previous PR did not merge.
- **#9 (sharing) is signed off for merging to `main`** (Ernie, 2026-11-20, ADR-025). This is not a
  production sign-off: the full RunLocalTests validate before any sandbox or production deploy still
  stands (ADR-016). #10 to #25 all contain #9's commits.
- Do not delete any branch until all 25 are merged.

## 3. The order

1. Merge **#1, #2, … #18** into `main`, one at a time, in that order.
2. Change the base of **#19, #20, #21, #22 and #23** to `main`: on each PR, click **Edit** next to the
   title, choose `main` in the base box, confirm. Each diff should now show only its own fix.
   Do this **before** merging any of them. Merging one while it still targets
   `feature/SCA-22-advisor-agent` puts the change on a branch that is already merged, so it never reaches `main`.
3. Merge **#19, #20, #21, #22, #23** into `main`, in that order.
4. Change the base of **#24** to `main`, then merge #24.
5. Change the base of **#25** to `main`, then merge #25.
6. Check: `main` now has every story. The **Commits** tab of each merged PR should show "merged into main".

## 4. If a PR was merged into the wrong branch

If #19 to #25 was merged while still targeting another PR's branch, its change sits on that branch,
not on `main`. Fix: open a new PR from that branch into `main` (it will contain only the missing change),
check its diff, merge it.

## 5. After merging

- Optionally delete the 25 head branches (all at once, after step 6).
- The org already has everything in #1 to #25 deployed; merging does not deploy anything.
- Before any sandbox or production deploy: full RunLocalTests validate first (ADR-016).

## 6. Dry run (2026-11-20, after the conflict fix)

Run by Orchestrate on a scratch copy: start from `main` (1c67b5d), merge each PR's head branch in number
order with a merge commit (`git merge --no-ff`), stop on any conflict. Same as what GitHub does once each
PR targets `main`. Script: merge the 25 heads below in order; the result is the union of all 25 PRs.

```
#1 feature/SCA-2-prerequisites (b9e8432): clean
#2 feature/SCA-10-scoring-settings (a12a3db): clean
#3 feature/SCA-3-outreach-log (de93dcc): clean
#4 feature/SCA-4-risk-fields (719764d): clean
#5 feature/SCA-7-classroom-activity (dcc836d): clean
#6 feature/SCA-5-permissions (a07e494): clean
#7 feature/SCA-8-demo-data (74d744e): clean
#8 feature/SCA-9-scoring-flow (01297a1): clean
#9 feature/SCA-5-sharing (d6505f8): clean
#10 feature/SCA-13-risk-crossing (e5662d1): clean
#11 feature/SCA-14-advisor-alert (19cac2d): clean
#12 feature/SCA-17-risk-summary-template (986c740): clean
#13 feature/SCA-18-outreach-draft-template (b50aead): clean
#14 feature/SCA-19-checkin-template (77cf375): clean
#15 feature/SCA-20-handoff-summary (7a253d6): clean
#16 feature/SCA-36-safe-messaging (32659c9): clean
#17 feature/SCA-31-live-assignments (f141457): clean
#18 feature/SCA-22-advisor-agent (2ca2fca): clean
#19 fix/SCA-2-deployable-baseline (0d908d8): clean
#20 fix/SCA-8-demo-dates-and-list-view (9afe37f): clean
#21 fix/SCA-5-uat-users (06094c1): clean
#22 fix/SCA-36-uat-message-tester (98bdd19): clean
#23 fix/SCA-43-trust-layer (c768a2e): clean
#24 fix/SCA-36-flow-access (f999df9): clean
#25 fix/SCA-22-qa-fixes (see the PR head; dry run passed at cf8eea4 and is re-run after each push): clean
```

Before the fix, #23 and #24 conflicted in `CONTEXT.md`, `context/goals.md`, `context/gotchas.md` and
`context/handoff.md`, and #25 also in `.gitignore`. Cause: the project-memory sync had written its own
"chore(context): sync project memory" commit to #1, #23, #24 and #25, each from a different base.

**What was changed (no force-push, no history rewritten):**
- #23 and #24: one merge commit each that brings in #1's memory commit (b9e8432) and sets `CONTEXT.md`,
  `context/` and `.gitignore` to the same content as #25. No force-app, docs or scripts file changed.
- #25: merged the updated #24 so it is still stacked on #24. No file changed by that merge.
- The PR bases are unchanged. #23's and #24's **Files changed** now also list the memory files.

## 7. Keeping the memory sync from doing this again

The sync commits `CONTEXT.md` and `context/` to the branch the Orchestrate session is working on. Two
sessions on two sibling branches therefore write two different copies, and the second PR conflicts.
- Merge the open PRs (#1 to #25) soon, so new work starts from a `main` that already has the memory files.
- After that, start each new branch from an up-to-date `main`, and stack new fix branches on the newest
  open branch, not on an older one (a single line of branches, never two siblings).
- If two open sibling branches are unavoidable, run this dry run before asking for merges; when it shows a
  memory-file conflict, merge the earlier branch's memory commit into the later one and give both the
  same memory files (as in section 6).
- Orchestrate cannot change where the sync writes. Asking Revecast to have it write to one branch only
  (the existing `orchestrate/context`) would remove the cause; until then, use the steps above.

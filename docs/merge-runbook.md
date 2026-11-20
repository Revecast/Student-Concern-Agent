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
- **#9 (sharing) must be signed off before you merge #9 or anything after it.** #10 to #25 all contain
  #9's commits, so merging any of them merges the sharing change too (ADR-016).
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

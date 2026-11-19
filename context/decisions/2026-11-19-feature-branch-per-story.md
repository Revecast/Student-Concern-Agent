# ADR-006: Feature branch per story

**Status:** Accepted · **Date:** 2026-11-19 · **Deciders:** the person running the build session (Delivery)

## Context
Commits straight to `main` are blocked in Orchestrate, and the session's working branch was set to `main`.

## Decision
Every build story gets its own branch, cut fresh from `origin/main`: `feature/SCA-<n>-<short-description>` (e.g. `feature/SCA-3-outreach-log`). Each merges to `main` through a pull request. Commit messages start with `[SCA-<n>]`.

## Consequences
More pull requests (one per story), but each change is easy to trace and review. Start each build session with the working branch set to the story's feature branch, not `main`.

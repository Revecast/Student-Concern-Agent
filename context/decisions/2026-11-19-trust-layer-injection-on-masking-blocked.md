# ADR-020 — Prompt-injection detection on; PII masking deferred until Data Cloud

**Status:** Accepted (narrows ADR-018) · **Date:** 2026-11-19 · **Deciders:** Ernie Maldonado (approved "turn it on, report the exact error if refused")

## Context
ADR-018 chose to turn on Trust Layer PII masking. The org refuses it: "Data Cloud is not provisioned, please finish Data Cloud Set up and retry."

## Decision
Turn on prompt-injection detection (deployed, read back). Leave PII masking off until Data Cloud is provisioned. Synthetic demo data only in the meantime.

## Consequences
SCA-43 stays In Progress. Audit trail is also unverified (depends on Data Cloud). Evidence in docs/trust-layer.md, PR #23.

#!/usr/bin/env bash
# Student Concern Agent — demo data load / reset (SCA-8).
# Usage: scripts/load-demo-data.sh [target-org-alias]   (default: jaxedupde-dev-ed)
#
# Safe to run any number of times: it updates the demo cohort in place and
# re-dates attendance and classroom logins relative to today. It never deletes.
# 1. Makes sure the "Advisor" case team role exists (a setup object, so it is
#    created in its own transaction before the data load).
# 2. Runs scripts/apex/load-demo-data.apex.
set -euo pipefail
ORG="${1:-jaxedupde-dev-ed}"
HERE="$(cd "$(dirname "$0")" && pwd)"

existing=$(sf data query -o "$ORG" --json -q "SELECT Id FROM CaseTeamRole WHERE Name = 'Advisor'" | jq -r '.result.totalSize')
if [ "$existing" = "0" ]; then
  echo "Creating case team role: Advisor (Edit access)"
  sf data create record -o "$ORG" -s CaseTeamRole -v "Name=Advisor AccessLevel=Edit" --json | jq -r '.result.id'
else
  echo "Case team role Advisor already exists"
fi

echo "Loading demo cohort into $ORG"
sf apex run -o "$ORG" -f "$HERE/apex/load-demo-data.apex" --json \
  | jq -r 'if .result.success then (.result.logs | split("\n") | map(select(test("SCA-8 demo load complete"))) | .[0] // "done") else "FAILED: " + (.result.compileProblem // .result.exceptionMessage) + " " + (.result.exceptionStackTrace // "") end'

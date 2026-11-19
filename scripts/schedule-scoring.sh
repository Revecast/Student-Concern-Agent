#!/usr/bin/env bash
# Student Concern Agent — move the nightly scorer's next run (SCA-9).
# A scheduled flow has no "run now" button, so for a demo or a test this
# re-deploys SCH_Score_First_Year_Students with a start time a few minutes away.
#
# Usage:
#   scripts/schedule-scoring.sh now [minutes] [org]   # run once in N minutes (default 3), then daily at that time
#   scripts/schedule-scoring.sh nightly [org]         # back to the normal 02:00 org time (05:00 Eastern)
#
# The start time is in the ORG's time zone (Pacific for jaxedupde-dev-ed), which this
# script reads from the org. Always run "nightly" afterwards. The repo file is not changed.
set -euo pipefail
MODE="${1:-now}"
if [ "$MODE" = "now" ]; then MINUTES="${2:-3}"; ORG="${3:-jaxedupde-dev-ed}"; else ORG="${2:-jaxedupde-dev-ed}"; fi
HERE="$(cd "$(dirname "$0")/.." && pwd)"
FLOW="$HERE/force-app/main/default/flows/SCH_Score_First_Year_Students.flow-meta.xml"
TZ_ORG=$(sf data query -o "$ORG" --json -q "SELECT TimeZoneSidKey FROM Organization" | jq -r '.result.records[0].TimeZoneSidKey')
if [ "$MODE" = "now" ]; then
  START_DATE=$(TZ="$TZ_ORG" date -d "+$MINUTES min" +%Y-%m-%d)
  START_TIME=$(TZ="$TZ_ORG" date -d "+$MINUTES min" +%H:%M:00)
else
  START_DATE=$(TZ="$TZ_ORG" date +%Y-%m-%d)   # Salesforce picks the next 02:00 on or after this date
  START_TIME="02:00:00"
fi
WORK=$(mktemp -d)
mkdir -p "$WORK/src/flows"
cp "$HERE/sfdx-project.json" "$WORK/"
sed -i 's#"path": "force-app"#"path": "src"#' "$WORK/sfdx-project.json"
sed -E "s#<startDate>[^<]*</startDate><startTime>[^<]*</startTime>#<startDate>$START_DATE</startDate><startTime>$START_TIME.000Z</startTime>#" \
  "$FLOW" > "$WORK/src/flows/SCH_Score_First_Year_Students.flow-meta.xml"
echo "Scheduling the scorer for $START_DATE $START_TIME ($TZ_ORG) in $ORG"
(cd "$WORK" && sf project deploy start -d src -o "$ORG" -l RunSpecifiedTests -t StudentAbsenceCounterTest --json | jq -r '.result.status')
sf data query -o "$ORG" --json -q "SELECT NextFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE 'SCH_Score_First_Year_Students%'" \
  | jq -r '"Next run (UTC): " + (.result.records[0].NextFireTime // "not found")'
rm -rf "$WORK"

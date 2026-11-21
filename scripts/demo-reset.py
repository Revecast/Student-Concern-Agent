#!/usr/bin/env python3
"""Student Concern Agent - demo reset (SCA-45).

Run it the evening before a demo:

    python3 scripts/demo-reset.py --demo-date 2026-12-02

What it does, in order (stops at the first problem):
  1. Finds the 21 demo students and UAT No-Advisor Student. Stops unless it finds exactly 22.
  2. Lists their leftovers: Tasks, Record Alerts, Student Outreach rows and emails.
  3. Exports every listed record, all fields, plus the 22 Contacts, to
     demo-backups/<UTC time>/ (CSV and JSON). Nothing is changed before the export is written.
  4. Asks you to type RESET (skip with --yes), then deletes the listed records and clears
     Risk Last Alerted Date on the 22 Contacts. Nothing else is touched.
  5. Reloads the demo data with every date counted back from the demo day. Jordan's last
     classroom login is loaded 3 days back (no login points).
  6. Runs the scorer once now. Jordan scores 4; it checks nobody is at 6 or more.
  7. Reloads with Jordan's last login 5 days back from the demo day (the simulated
     classroom system "catches up"). No score is written by hand.
  8. Puts the scorer back on its 02:00 Pacific schedule. That run, on the demo day, takes
     Jordan from 4 to 7 and the normal flows alert his advisor (the presenter).

--rehearse uses today as the demo day and, instead of waiting for 02:00, runs the scorer a
second time straight away so you can see the alert now. --dry-run stops after the export and the count by student.

On demo morning run --check: one PASS/FAIL line each for Jordan, his alert/Task/outreach, other
students, the expected score table and the scorer's last run. It only reads; it changes nothing.

The script never deletes anything outside those 22 students, never touches the 220 bulk-test
students, and never edits a risk score. Deleted records stay in the Recycle Bin for 15 days.
"""
import argparse
import re
import shutil
import csv
import datetime as dt
import json
import os
import subprocess
import sys
import tempfile
import time
from zoneinfo import ZoneInfo

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOADER = os.path.join(ROOT, "scripts", "apex", "load-demo-data.apex")
BULK_ACCOUNT = "DEMO - Bulk Test Students (safe to delete)"
DEMO_DOMAIN = "@student.jaxstate.example"
NO_ADVISOR_EMAIL = "uat.noadvisor@uat.student.jaxstate.example"
EXPECTED_STUDENTS = 22  # 21 demo students + UAT No-Advisor Student
ALERT_LIMIT = 6
API = "v68.0"
PRESENTER_USERNAME = "ernie.maldonado@revecast.io.edupde"  # same advisor as load-demo-data.apex
JORDAN_DEMO_LOGIN_DAYS = 5

sys.path.insert(0, os.path.join(ROOT, "scripts"))
import crossing_table  # noqa: E402  (the scoring model the expected table comes from)


def sf(args, check=True):
    """Runs an sf CLI command with --json and returns the parsed result."""
    proc = subprocess.run(["sf"] + args + ["--json"], capture_output=True, text=True)
    try:
        out = json.loads(proc.stdout)
    except json.JSONDecodeError:
        sys.exit("sf returned no JSON for: sf " + " ".join(args) + "\n" + proc.stderr[-2000:])
    if check and out.get("status", 0) != 0:
        sys.exit("sf failed: sf " + " ".join(args[:3]) + "\n" + out.get("message", json.dumps(out)[:2000]))
    return out


def query(org, soql):
    """Runs a SOQL query and returns all records (follows queryMore)."""
    records = []
    out = sf(["data", "query", "-o", org, "-q", soql])
    records.extend(out["result"]["records"])
    return [{k: v for k, v in r.items() if k != "attributes"} for r in records]


def rest(org, path, method="GET", body=None):
    """Calls the org's REST API and returns the parsed body."""
    args = ["api", "request", "rest", path, "-o", org, "--method", method]
    tmp = None
    if body is not None:
        tmp = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
        json.dump(body, tmp)
        tmp.close()
        args += ["--body", "@" + tmp.name]
    elif method != "GET":
        # sf api request rest refuses any non-GET call without a non-empty --body
        # ("No 'mode' found in 'body' entry"). Deletes use delete_records() instead.
        raise ValueError("rest() needs a body for " + method)
    proc = subprocess.run(["sf"] + args, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    if tmp:
        os.unlink(tmp.name)
    if proc.returncode != 0:
        sys.exit("REST " + method + " " + path + " failed:\n" + (proc.stdout + proc.stderr)[-2000:])
    return json.loads(proc.stdout) if proc.stdout.strip() else None


def id_list(ids):
    return "(" + ",".join("'" + i + "'" for i in ids) + ")" if ids else "('000000000000000')"


def chunks(items, size):
    for i in range(0, len(items), size):
        yield items[i:i + size]


def find_students(org):
    rows = query(org, "SELECT Id, Name, Email, AccountId, Account.Name FROM Contact WHERE "
                 "(Email LIKE '%" + DEMO_DOMAIN + "' AND Account.Name != '" + BULK_ACCOUNT + "') "
                 "OR Email = '" + NO_ADVISOR_EMAIL + "' ORDER BY Name")
    # LIKE '%@student...' also matches '@uat.student...' only through the explicit OR above.
    rows = [r for r in rows if r["Email"].lower().endswith(DEMO_DOMAIN) or r["Email"].lower() == NO_ADVISOR_EMAIL]
    if len(rows) != EXPECTED_STUDENTS:
        sys.exit("Expected %d students, found %d. Nothing changed. Found: %s"
                 % (EXPECTED_STUDENTS, len(rows), ", ".join(r["Name"] for r in rows)))
    return rows


def find_leftovers(org, student_ids):
    """Every Task, Record Alert, Student Outreach row and email tied to the students."""
    sid = id_list(student_ids)
    cases = [r["Id"] for r in query(org, "SELECT Id FROM Case WHERE ContactId IN " + sid)]
    parents = id_list(student_ids + cases)
    emails = set(r["EmailMessageId"] for r in query(
        org, "SELECT EmailMessageId FROM EmailMessageRelation WHERE RelationId IN " + sid))
    emails |= set(r["Id"] for r in query(org, "SELECT Id FROM EmailMessage WHERE RelatedToId IN " + parents))
    tasks = set(r["Id"] for r in query(org, "SELECT Id FROM Task WHERE WhoId IN " + sid))
    tasks |= set(r["Id"] for r in query(org, "SELECT Id FROM Task WHERE WhatId IN " + parents))
    alerts = set(r["Id"] for r in query(org, "SELECT Id FROM RecordAlert WHERE WhatId IN " + parents))
    alerts |= set(r["Id"] for r in query(org, "SELECT Id FROM RecordAlert WHERE ParentId IN " + parents))
    outreach = set(r["Id"] for r in query(org, "SELECT Id FROM Student_Outreach__c WHERE Student__c IN " + sid))
    return {"EmailMessage": sorted(emails), "Task": sorted(tasks),
            "RecordAlert": sorted(alerts), "Student_Outreach__c": sorted(outreach)}


def queryable_fields(org, sobject):
    out = sf(["sobject", "describe", "-s", sobject, "-o", org])
    return [f["name"] for f in out["result"]["fields"]
            if f["type"] not in ("address", "location", "base64")]


def export(org, folder, sobject, ids):
    """Writes every field of the given records to <sobject>.csv and .json."""
    fields = queryable_fields(org, sobject)
    rows = []
    for part in chunks(ids, 150):
        rows += query(org, "SELECT " + ",".join(fields) + " FROM " + sobject + " WHERE Id IN " + id_list(part))
    with open(os.path.join(folder, sobject + ".json"), "w") as fh:
        json.dump(rows, fh, indent=1, default=str)
    with open(os.path.join(folder, sobject + ".csv"), "w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({k: (json.dumps(v) if isinstance(v, (dict, list)) else v) for k, v in row.items()})
    if len(rows) != len(ids):
        sys.exit("Export of %s wrote %d of %d records. Nothing changed." % (sobject, len(rows), len(ids)))
    return len(rows)


def existing(org, sobject, ids):
    """The subset of ids that still exist (not deleted)."""
    found = set()
    for part in chunks(list(ids), 150):
        found |= set(r["Id"] for r in query(org, "SELECT Id FROM " + sobject + " WHERE Id IN " + id_list(part)))
    return found


def delete_records(org, sobject, ids, done):
    """Deletes one record per call with 'sf data delete record' and reads each call's exit code.

    A record that is already gone (an email takes its 'Email:' Task with it) counts as fine.
    Any other failure stops the script and prints every ID deleted so far. `done` collects the
    IDs that are gone, across objects, so the stop message is complete."""
    deleted = already = 0
    for rid in ids:
        proc = subprocess.run(["sf", "data", "delete", "record", "-s", sobject, "-i", rid, "-o", org, "--json"],
                              capture_output=True, text=True, stdin=subprocess.DEVNULL)
        if proc.returncode == 0:
            deleted += 1
            done.append(rid)
            continue
        if not existing(org, sobject, [rid]):
            already += 1
            done.append(rid)
            continue
        try:
            err = json.loads(proc.stdout)
            reason = "%s: %s" % (err.get("name"), err.get("message"))
        except json.JSONDecodeError:
            reason = (proc.stdout + proc.stderr)[-500:]
        sys.exit("STOPPED. Delete of %s %s failed (exit %d): %s\nAlready deleted (%d): %s"
                 % (sobject, rid, proc.returncode, reason, len(done), ", ".join(done) or "none"))
    return deleted, already


def student_of(org, folder, leftovers, students):
    """Maps every leftover ID to its student's name, from the exported rows."""
    names = {s["Id"]: s["Name"] for s in students}
    case_owner = {r["Id"]: r["ContactId"] for r in query(
        org, "SELECT Id, ContactId FROM Case WHERE ContactId IN " + id_list(list(names)))}
    keys = {"Task": ("WhoId", "WhatId"), "RecordAlert": ("WhatId", "ParentId"),
            "Student_Outreach__c": ("Student__c",), "EmailMessage": ("RelatedToId",)}
    out = {}
    for sobject, ids in leftovers.items():
        if not ids:
            continue
        for row in json.load(open(os.path.join(folder, sobject + ".json"))):
            who = "unknown"
            for k in keys[sobject]:
                v = row.get(k)
                v = case_owner.get(v, v)
                if v in names:
                    who = names[v]
                    break
            out[row["Id"]] = who
    return out


def run_loader(org, demo_date, jordan_days):
    src = open(LOADER).read()
    old_date = "Date TODAY_DATE = Date.today();"
    old_days = "Integer JORDAN_DAYS_SINCE_LOGIN = 5;"
    assert src.count(old_date) == 1 and src.count(old_days) == 1, "loader settings lines not found"
    src = src.replace(old_date, "Date TODAY_DATE = Date.newInstance(%d, %d, %d);" % (demo_date.year, demo_date.month, demo_date.day))
    src = src.replace(old_days, "Integer JORDAN_DAYS_SINCE_LOGIN = %d;" % jordan_days)
    with tempfile.NamedTemporaryFile("w", suffix=".apex", delete=False) as fh:
        fh.write(src)
    out = sf(["apex", "run", "-o", org, "-f", fh.name], check=False)
    os.unlink(fh.name)
    result = out.get("result", {})
    if not result.get("success"):
        sys.exit("Demo load failed: " + str(result.get("compileProblem") or result.get("exceptionMessage")))
    line = [l for l in result.get("logs", "").split("\n") if "SCA-8 demo load complete" in l]
    print("   " + (line[0].split("|")[-1] if line else "load done"))


FLOW_FILE = os.path.join(ROOT, "force-app", "main", "default", "flows", "SCH_Score_First_Year_Students.flow-meta.xml")


def schedule(org, mode, minutes=2):
    """Moves the scorer's start time by re-deploying its flow with a new schedule.

    A scheduled flow has no run-now button. 'now' = once in `minutes`, then daily at that time
    (always follow with 'nightly'); 'nightly' = back to 02:00 org time. Pure Python, so it works
    on macOS and Linux alike (no GNU date or jq). The repo's flow file is not changed."""
    org_tz = ZoneInfo(query(org, "SELECT TimeZoneSidKey FROM Organization")[0]["TimeZoneSidKey"])
    now = dt.datetime.now(org_tz)
    if mode == "now":
        start = now + dt.timedelta(minutes=minutes)
        start_date, start_time = start.strftime("%Y-%m-%d"), start.strftime("%H:%M:00")
    else:
        start_date, start_time = now.strftime("%Y-%m-%d"), "02:00:00"  # next 02:00 on or after today
    src = open(FLOW_FILE).read()
    new_src, n = re.subn(r"<startDate>[^<]*</startDate><startTime>[^<]*</startTime>",
                         "<startDate>%s</startDate><startTime>%s.000Z</startTime>" % (start_date, start_time), src)
    if n != 1:
        sys.exit("Could not find the schedule in " + FLOW_FILE)
    work = tempfile.mkdtemp()
    os.makedirs(os.path.join(work, "src", "flows"))
    project = json.load(open(os.path.join(ROOT, "sfdx-project.json")))
    project["packageDirectories"] = [{"path": "src", "default": True}]
    json.dump(project, open(os.path.join(work, "sfdx-project.json"), "w"))
    with open(os.path.join(work, "src", "flows", os.path.basename(FLOW_FILE)), "w") as fh:
        fh.write(new_src)
    print("   Scheduling the scorer for %s %s (%s) in %s" % (start_date, start_time, org_tz.key, org))
    proc = subprocess.run(["sf", "project", "deploy", "start", "-d", "src", "-o", org, "-l", "RunSpecifiedTests",
                           "-t", "StudentAbsenceCounterTest", "-w", "15", "--json"],
                          cwd=work, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    shutil.rmtree(work, ignore_errors=True)
    try:
        status = json.loads(proc.stdout)["result"]["status"]
    except (json.JSONDecodeError, KeyError, TypeError):
        status = "unknown"
    if status != "Succeeded":
        sys.exit("Scheduling the scorer failed (deploy status %s):\n%s" % (status, (proc.stdout + proc.stderr)[-1500:]))
    cron = query(org, "SELECT NextFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE 'SCH_Score_First_Year_Students%'")
    if len(cron) != 1:
        sys.exit("Expected one scorer schedule, found %d." % len(cron))
    nxt = dt.datetime.fromisoformat(cron[0]["NextFireTime"].replace("+0000", "+00:00")).astimezone(org_tz)
    print("   Succeeded. Next run: %s" % nxt.strftime("%Y-%m-%d %H:%M %Z"))
    return nxt


def score_now(org, student_ids, label):
    """Runs the scorer in about 2 minutes and waits until all 21 demo students are rescored."""
    started = dt.datetime.now(dt.timezone.utc)
    schedule(org, "now", 2)
    demo_ids = id_list(student_ids)
    deadline = time.time() + 15 * 60
    while time.time() < deadline:
        time.sleep(30)
        rows = query(org, "SELECT Id, Risk_Scored_At__c FROM Contact WHERE Id IN " + demo_ids
                     + " AND Email LIKE '%" + DEMO_DOMAIN + "'")
        done = [r for r in rows if r["Risk_Scored_At__c"]
                and dt.datetime.fromisoformat(r["Risk_Scored_At__c"].replace("+0000", "+00:00")) >= started]
        if len(done) == len(rows):
            time.sleep(20)  # let the record-triggered alert flow finish
            print("   %s: all %d demo students rescored" % (label, len(rows)))
            return
    sys.exit("The scorer did not finish within 15 minutes (%s). Run 'scripts/schedule-scoring.sh nightly' "
             "and check Setup > Paused and Failed Flow Interviews." % label)


def scores(org, student_ids):
    return query(org, "SELECT Name, Risk_Score__c, Risk_Reason__c, Risk_Last_Alerted_Date__c FROM Contact "
                 "WHERE Id IN " + id_list(student_ids) + " ORDER BY Risk_Score__c DESC NULLS LAST, Name")


def check(org, org_tz):
    """Read-only demo-morning check. Prints one PASS/FAIL line per item and changes nothing."""
    today = dt.datetime.now(org_tz).date()
    results = []

    def line(ok, label, detail):
        results.append(ok)
        print("%s  %s: %s" % ("PASS" if ok else "FAIL", label, detail))

    students = find_students(org)
    ids = [s["Id"] for s in students]
    rows = {r["Name"]: r for r in query(org, "SELECT Id, Name, Risk_Score__c, Risk_Reason__c, Risk_Last_Alerted_Date__c, "
                                        "Risk_Scored_At__c FROM Contact WHERE Id IN " + id_list(ids))}
    jordan = rows["Jordan Rivera"]
    me = query(org, "SELECT Id FROM User WHERE Username = '" + PRESENTER_USERNAME + "'")[0]["Id"]
    login = query(org, "SELECT Last_Login__c FROM Classroom_Activity__c WHERE Student__c = '" + jordan["Id"]
                  + "' ORDER BY Last_Login__c DESC LIMIT 1")
    login_day = dt.datetime.fromisoformat(login[0]["Last_Login__c"].replace("+0000", "+00:00")).astimezone(org_tz).date()
    demo_day = login_day + dt.timedelta(days=JORDAN_DEMO_LOGIN_DAYS)
    k = (today - demo_day).days
    print("Org date %s; demo data dated to %s (demo day %+d)" % (today, demo_day, k))

    # 1. Jordan at 7 with today's alert date
    alerted = jordan["Risk_Last_Alerted_Date__c"]
    line(jordan["Risk_Score__c"] == 7 and alerted == today.isoformat(), "Jordan at 7, alerted today",
         "score %s, last alerted %s" % (jordan["Risk_Score__c"], alerted or "blank"))

    # 2. exactly one alert, one open Task, two outreach rows - all Jordan's, for the presenter
    cases = [r["Id"] for r in query(org, "SELECT Id FROM Case WHERE ContactId IN " + id_list(ids))]
    parents = id_list(ids + cases)
    jordan_parents = set([jordan["Id"]] + [r["Id"] for r in query(
        org, "SELECT Id FROM Case WHERE ContactId = '" + jordan["Id"] + "'")])
    alerts = query(org, "SELECT Name, WhatId, ParentId, OwnerId FROM RecordAlert WHERE IsActive = true")
    tasks = query(org, "SELECT Subject, WhoId, WhatId, OwnerId FROM Task WHERE IsClosed = false AND "
                  "(WhoId IN " + id_list(ids) + " OR WhatId IN " + parents + ")")
    outreach = query(org, "SELECT Name, Student__c, Channel__c, Recipient_User__c, Status__c FROM Student_Outreach__c "
                     "WHERE Student__c IN " + id_list(ids))
    ok_alerts = len(alerts) == 1 and (alerts[0]["WhatId"] in jordan_parents or alerts[0]["ParentId"] in jordan_parents) \
        and alerts[0]["OwnerId"] == me
    ok_tasks = len(tasks) == 1 and (tasks[0]["WhoId"] in jordan_parents or tasks[0]["WhatId"] in jordan_parents) \
        and tasks[0]["OwnerId"] == me
    ok_out = len(outreach) == 2 and all(o["Student__c"] == jordan["Id"] and o["Recipient_User__c"] == me
                                        and o["Status__c"] == "Sent" for o in outreach) \
        and sorted(o["Channel__c"] for o in outreach) == ["In-App Notification", "Task"]
    line(ok_alerts and ok_tasks and ok_out, "One alert, one open Task, two outreach rows, all Jordan's, for you",
         "active alerts in the org %d (%s); open Tasks %d; outreach rows %d (%s)" % (
             len(alerts), ", ".join(a["Name"] for a in alerts) or "none", len(tasks), len(outreach),
             ", ".join("%s %s" % (o["Name"], o["Channel__c"]) for o in outreach) or "none"))

    # 3. no other demo student at 6 or more (UAT No-Advisor Student is not a demo student)
    high = ["%s %s" % (n, r["Risk_Score__c"]) for n, r in rows.items()
            if n not in ("Jordan Rivera", "UAT No-Advisor Student") and (r["Risk_Score__c"] or 0) >= ALERT_LIMIT]
    line(not high, "No other demo student at %d or more" % ALERT_LIMIT, ", ".join(high) or "nobody")

    # 4. expected score table (the scoring model for this demo day)
    # The evening before (demo day -1) the reset's first run scored Jordan with a 3-day login.
    model = crossing_table.crossings(k + 1) if k >= 0 else {}
    wrong = []
    for name, (absences, login_days, grades) in crossing_table.COHORT.items():
        if k >= 0:
            expected = model[name][0][k]
        else:
            evening = crossing_table.JORDAN_EVENING_LOGIN if name == "Jordan Rivera" else login_days
            expected = crossing_table.score(absences, evening, grades, k)
        if rows[name]["Risk_Score__c"] != expected:
            wrong.append("%s %s (expected %s)" % (name, rows[name]["Risk_Score__c"], expected))
    line(not wrong, "Scores match the expected table for demo day %+d" % k,
         ", ".join(wrong) if wrong else "21 of 21 as expected")

    # 5. the scorer's last run and its schedule
    cron = query(org, "SELECT State, NextFireTime, PreviousFireTime FROM CronTrigger "
                 "WHERE CronJobDetail.Name LIKE 'SCH_Score_First_Year_Students%'")
    demo_rows = [r for n, r in rows.items() if n != "UAT No-Advisor Student"]
    last = max(dt.datetime.fromisoformat(r["Risk_Scored_At__c"].replace("+0000", "+00:00")) for r in demo_rows
               if r["Risk_Scored_At__c"]).astimezone(org_tz)
    scored_today = sum(1 for r in demo_rows if r["Risk_Scored_At__c"] and dt.datetime.fromisoformat(
        r["Risk_Scored_At__c"].replace("+0000", "+00:00")).astimezone(org_tz).date() == today)
    state = cron[0]["State"] if len(cron) == 1 else "%d schedules" % len(cron)
    nxt = dt.datetime.fromisoformat(cron[0]["NextFireTime"].replace("+0000", "+00:00")).astimezone(org_tz) \
        if len(cron) == 1 and cron[0]["NextFireTime"] else None
    line(len(cron) == 1 and state == "WAITING" and scored_today == 21 and nxt is not None and nxt.hour == 2,
         "Scorer ran today and is scheduled",
         "last run %s (%d of 21 scored today); schedule %s, next run %s" % (
             last.strftime("%Y-%m-%d %H:%M %Z"), scored_today, state, nxt.strftime("%Y-%m-%d %H:%M %Z") if nxt else "none"))

    print("Scores now:")
    for name, r in sorted(rows.items(), key=lambda x: (-(x[1]["Risk_Score__c"] or 0), x[0])):
        print("   %-24s %s  %s" % (name, r["Risk_Score__c"], r["Risk_Reason__c"] or ""))
    print("%s: %d of %d checks passed. Nothing was changed." % ("READY" if all(results) else "NOT READY",
                                                              sum(results), len(results)))
    sys.exit(0 if all(results) else 1)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--demo-date", help="demo day, YYYY-MM-DD (not needed with --rehearse)")
    ap.add_argument("--org", default="jaxedupde-dev-ed")
    ap.add_argument("--rehearse", action="store_true", help="demo day = today; show the alert now")
    ap.add_argument("--dry-run", action="store_true", help="list and export only; change nothing")
    ap.add_argument("--yes", action="store_true", help="do not ask before deleting")
    ap.add_argument("--score-now", action="store_true", help="Plan B: run the scorer now, put 02:00 back, "
                    "then --check. Deletes nothing")
    ap.add_argument("--check", action="store_true", help="demo morning: read-only PASS/FAIL check; changes nothing")
    ap.add_argument("--approved-ids", help="ids.json of an earlier, approved export; stop if any "
                    "record to delete is not in it")
    a = ap.parse_args()

    org_tz = ZoneInfo(query(a.org, "SELECT TimeZoneSidKey FROM Organization")[0]["TimeZoneSidKey"])
    today = dt.datetime.now(org_tz).date()
    if a.score_now:
        # Plan B (demo morning, Jordan still at 4): score now, wait, put 02:00 back, then check.
        started = time.time()
        students = find_students(a.org)
        print("Plan B: scoring all students now")
        score_now(a.org, [s["Id"] for s in students], "scorer")
        print("Putting the scorer back on 02:00 Pacific")
        schedule(a.org, "nightly")
        print("Took %d minutes. Checking:" % round((time.time() - started) / 60))
        check(a.org, org_tz)
        return
    if a.check:
        check(a.org, org_tz)
        return
    if a.rehearse:
        demo_date = today
    elif a.demo_date:
        demo_date = dt.date.fromisoformat(a.demo_date)
        if demo_date <= today:
            sys.exit("The demo day must be after today (%s, org time). Use --rehearse to try it today." % today)
        if demo_date != today + dt.timedelta(days=1):
            print("Note: the demo day is not tomorrow. The alert arrives at 02:00 Pacific on %s." % demo_date)
    else:
        sys.exit("Give --demo-date YYYY-MM-DD or --rehearse.")

    print("1. Finding the students")
    students = find_students(a.org)
    student_ids = [s["Id"] for s in students]
    print("   %d students (21 demo + UAT No-Advisor Student)" % len(students))

    print("2. Listing leftovers")
    leftovers = find_leftovers(a.org, student_ids)
    for k, v in leftovers.items():
        print("   %-20s %d" % (k, len(v)))

    print("3. Exporting")
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    folder = os.path.join(ROOT, "demo-backups", stamp)
    os.makedirs(folder, exist_ok=True)
    export(a.org, folder, "Contact", student_ids)
    for sobject, ids in leftovers.items():
        if ids:
            export(a.org, folder, sobject, ids)
    with open(os.path.join(folder, "ids.json"), "w") as fh:
        json.dump(leftovers, fh, indent=1)
    print("   export written to " + os.path.relpath(folder, ROOT))
    # Only IDs in the backup just written (and in the approved list, when given) are deleted.
    backup = json.load(open(os.path.join(folder, "ids.json")))
    allowed = set(i for v in backup.values() for i in v)
    if a.approved_ids:
        approved = json.load(open(a.approved_ids))
        allowed &= set(i for v in approved.values() for i in v)
    outside = [i for v in leftovers.values() for i in v if i not in allowed]
    if outside:
        sys.exit("STOPPED. %d record(s) are not in the backup/approved list: %s. Nothing deleted."
                 % (len(outside), ", ".join(outside)))

    total = sum(len(v) for v in leftovers.values())
    who = student_of(a.org, folder, leftovers, students)
    print("   To delete: %d records" % total)
    for sobject, ids in leftovers.items():
        print("     %-20s %d" % (sobject, len(ids)))
    by_student = {}
    for sobject, ids in leftovers.items():
        for i in ids:
            by_student.setdefault(who.get(i, "unknown"), {}).setdefault(sobject, 0)
            by_student[who.get(i, "unknown")][sobject] += 1
    for name in sorted(by_student):
        parts = ", ".join("%s %d" % (k, v) for k, v in sorted(by_student[name].items()))
        print("     %-24s %s" % (name, parts))
    if "unknown" in by_student:
        sys.exit("STOPPED. Some records could not be matched to a student. Nothing deleted.")
    if a.dry_run:
        print("Dry run: nothing changed.")
        return
    if total and not a.yes:
        answer = input("   Delete these %d records (Recycle Bin for 15 days)? Type RESET to continue: " % total)
        if answer.strip() != "RESET":
            sys.exit("Stopped. Nothing changed.")

    print("4. Clearing leftovers")
    # Tasks before emails, so no Task is taken away by its email mid-run; a record that is
    # already gone still counts as fine. Only records in the export are deleted.
    done = []
    for sobject in ("Task", "RecordAlert", "Student_Outreach__c", "EmailMessage"):
        if not leftovers[sobject]:
            continue
        deleted, already = delete_records(a.org, sobject, leftovers[sobject], done)
        print("   %-20s %d deleted%s" % (sobject, deleted, ", %d already gone" % already if already else ""))
    remaining = {k: sorted(existing(a.org, k, v)) for k, v in leftovers.items() if v}
    print("   Check: %d of %d listed IDs still exist" % (sum(len(v) for v in remaining.values()), total))
    if any(remaining.values()):
        sys.exit("STOPPED. Still present after delete: " + json.dumps(remaining))
    rest(a.org, "/services/data/" + API + "/composite/sobjects", "PATCH", {
        "allOrNone": True,
        "records": [{"attributes": {"type": "Contact"}, "id": i, "Risk_Last_Alerted_Date__c": None} for i in student_ids]})
    left = find_leftovers(a.org, student_ids)
    if any(left.values()):
        sys.exit("Records appeared after the export and were not deleted: " + json.dumps(left))
    print("   Risk Last Alerted Date cleared on %d students; no leftovers remain" % len(student_ids))

    print("5. Loading demo data for %s (Jordan: last login 3 days earlier)" % demo_date)
    run_loader(a.org, demo_date, 3)

    print("6. Scoring now (the 'evening before' score)")
    score_now(a.org, student_ids, "first run")
    first = scores(a.org, student_ids)
    jordan = [r for r in first if r["Name"] == "Jordan Rivera"][0]
    high = [r["Name"] for r in first if (r["Risk_Score__c"] or 0) >= ALERT_LIMIT and r["Name"] != "UAT No-Advisor Student"]
    print("   Jordan %s; at %d or more: %s" % (jordan["Risk_Score__c"], ALERT_LIMIT, ", ".join(high) or "nobody"))
    if (jordan["Risk_Score__c"] or 0) >= ALERT_LIMIT or high:
        schedule(a.org, "nightly")
        sys.exit("Expected everyone below %d after the first run. Stopped; scorer is back on 02:00." % ALERT_LIMIT)

    print("6b. Checking the first run alerted nobody")
    if any(find_leftovers(a.org, student_ids).values()):
        schedule(a.org, "nightly")
        sys.exit("The first scoring run created alerts or Tasks. Stopped; scorer is back on 02:00.")

    print("7. Loading demo data again (Jordan: last login 5 days before the demo day)")
    run_loader(a.org, demo_date, 5)

    if a.rehearse:
        print("8. Rehearsal: scoring again now (stands in for the 02:00 run)")
        score_now(a.org, student_ids, "second run")
        schedule(a.org, "nightly")
    else:
        print("8. Putting the scorer back on 02:00 Pacific")
        schedule(a.org, "nightly")
        cron = query(a.org, "SELECT NextFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE 'SCH_Score_First_Year_Students%'")
        nxt = dt.datetime.fromisoformat(cron[0]["NextFireTime"].replace("+0000", "+00:00")).astimezone(org_tz)
        if nxt.date() != demo_date and demo_date == today + dt.timedelta(days=1):
            sys.exit("Next scorer run is %s, not 02:00 on %s. Check the schedule." % (nxt, demo_date))
        print("   Jordan's alert will arrive at %s" % nxt.strftime("%Y-%m-%d %H:%M %Z"))

    print("Done. Scores now:")
    for r in scores(a.org, student_ids):
        print("   %-24s %s  %s" % (r["Name"], r["Risk_Score__c"], r["Risk_Reason__c"] or ""))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Student Concern Agent - which night each demo student crosses the alert limit (SCA-45).

Replays the nightly scorer's rules (docs/risk-score.md, Risk Score Setting defaults) on the
demo cohort in scripts/apex/load-demo-data.apex, for a load dated to demo day D, assuming
nobody reruns the reset. Read-only: it does not touch the org.

    python3 scripts/crossing_table.py --demo-date 2026-12-02 [--nights 16]

Model (kept in step with the loader and the scorer):
  - each course met 2, 4, 9 and 11 days before D; absences take BIO 101's newest sessions first;
    an absence counts while it is on or after (run date - 14 days); 2 points each, max 6
  - days since login on run night D+k = loaded days + k; 5-9 days = 3 points, 10+ = 5
  - grades never change after the load: below 70 = 3, letter-band drop = 2
  - the reset scores once on D-1 (the evening before); after that one run per night at 02:00
  - an alert fires when the score goes from below 6 to 6 or more and the student was not
    alerted in the last 7 days (the reset clears the alert date)
"""
import argparse
import datetime as dt

# key: (absences, days since login, [(current, two weeks ago) x3])
COHORT = {
    "Jordan Rivera":  (2, 5, [(84, 86), (81, 83), (88, 88)]),
    "Avery Chen":     (0, 11, [(79, 79), (85, 85), (77, 78)]),
    "Riley Patel":    (2, 1, [(88, 88), (91, 90), (84, 85)]),
    "Quinn Okafor":   (1, 2, [(77, 81), (86, 86), (90, 90)]),
    "Taylor Brooks":  (1, 2, [(92, 92), (88, 87), (85, 85)]),
    "Morgan Silva":   (0, 6, [(83, 83), (79, 79), (86, 85)]),
    "Casey Nguyen":   (0, 1, [(65, 66), (72, 73), (75, 74)]),
    "Alex Romero":    (0, 1, [(90, 89), (93, 92), (88, 88)]),
    "Sam Kowalski":   (0, 2, [(86, 85), (82, 82), (79, 79)]),
    "Jamie Haddad":   (0, 1, [(94, 94), (91, 91), (96, 95)]),
    "Drew Mensah":    (0, 3, [(81, 81), (84, 83), (78, 78)]),
    "Pat Lindqvist":  (0, 1, [(88, 87), (85, 86), (89, 89)]),
    "Reese Tanaka":   (0, 2, [(76, 76), (82, 81), (80, 80)]),
    "Skyler Adeyemi": (0, 1, [(91, 90), (87, 87), (92, 92)]),
    "Rowan Garcia":   (0, 1, [(84, 84), (88, 88), (83, 82)]),
    "Emery Walsh":    (0, 2, [(79, 78), (81, 81), (85, 85)]),
    "Hayden Kim":     (0, 1, [(87, 87), (90, 89), (86, 86)]),
    "Logan Petrov":   (0, 3, [(82, 82), (77, 77), (84, 84)]),
    "Parker Diallo":  (0, 1, [(93, 93), (89, 89), (91, 90)]),
    "Blake Moreau":   (0, 2, [(78, 77), (83, 83), (80, 80)]),
    "Cameron Iyer":   (0, 1, [(85, 85), (86, 85), (88, 88)]),
}
SESSIONS = [2, 4, 9, 11]          # days before D, newest first, per course (BIO, ENG, MATH)
LIMIT, COOLDOWN = 6, 7
JORDAN_EVENING_LOGIN = 3          # demo-reset.py scores Jordan with this before the reload


def band(grade):
    return 4 if grade >= 90 else 3 if grade >= 80 else 2 if grade >= 70 else 1 if grade >= 60 else 0


def score(absences, login_days, grades, k):
    """Score on run night D+k."""
    absent_days = [SESSIONS[i % 4] for i in range(absences)]  # BIO newest first, then ENG
    in_window = sum(1 for days_before in absent_days if -days_before >= k - 14)
    points = min(in_window * 2, 6)
    days = login_days + k
    points += 5 if days >= 10 else 3 if days >= 5 else 0
    points += 3 if any(cur < 70 for cur, _ in grades) else 0
    points += 2 if any(band(cur) < band(old) for cur, old in grades) else 0
    return points


def crossings(nights):
    """{name: [(k, score)...]} and the alert nights per student."""
    result = {}
    for name, (absences, login, grades) in COHORT.items():
        evening_login = JORDAN_EVENING_LOGIN if name == "Jordan Rivera" else login
        prev = score(absences, evening_login, grades, -1)
        last_alert = None
        row, alerts = [], []
        for k in range(0, nights):
            now = score(absences, login, grades, k)
            if prev < LIMIT <= now and (last_alert is None or k - last_alert >= COOLDOWN):
                alerts.append(k)
                last_alert = k
            row.append(now)
            prev = now
        result[name] = (row, alerts)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--demo-date", required=True)
    parser.add_argument("--nights", type=int, default=16)
    args = parser.parse_args()
    demo = dt.date.fromisoformat(args.demo_date)
    data = crossings(args.nights)
    print(f"Load dated to {demo}. Score at each 02:00 Pacific run; * = alert to the advisor.")
    header = "".join(f"{(demo + dt.timedelta(k)).strftime('%m/%d'):>6}" for k in range(args.nights))
    print(f"{'':16}{header}")
    for name, (row, alerts) in data.items():
        if max(row) == 0:
            continue
        cells = "".join(f"{str(s) + ('*' if k in alerts else ''):>6}" for k, s in enumerate(row))
        print(f"{name:16}{cells}")
    print("All other demo students stay at 0.")
    print("Alert nights:")
    for name, (_, alerts) in data.items():
        for k in alerts:
            print(f"   {(demo + dt.timedelta(k)).isoformat()} 02:00 Pacific  {name}  (demo day + {k})")


if __name__ == "__main__":
    main()

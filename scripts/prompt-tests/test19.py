import re
from gen_test import run
times = "Tuesday, November 24, 10:00 AM ET\nWednesday, November 25, 1:30 PM ET\nMonday, November 30, 3:00 PM ET"
banned = ["!", "missed","absent","failing","behind","concern","worried","risk","flag","score","grade","attendance","class"]
BR = re.compile(r"[\[\]{}]")
for cid, name in [("003iw000003anTVAAY","Jordan"),("003iw000003anTiAAI","Skyler"),("003iw000002glRBAAY","Rose (no data)")]:
    t = run("Student_Checkin_Message", {"Input:Student": {"value": {"id": cid}}, "Input:Meeting_Times": {"value": times}})
    low = t.lower()
    pos = [low.find(x.lower()) for x in ["November 24, 10:00","November 25, 1:30","November 30, 3:00"]]
    ok = all(p >= 0 for p in pos) and pos == sorted(pos)
    bad = [b for b in banned if b in low]
    print("=== %s: %d chars | times in order: %s | banned: %s | brackets: %s" % (name, len(t), ok, bad, bool(BR.search(t))))
    print(t, "\n")

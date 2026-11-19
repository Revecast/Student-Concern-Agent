import re, sys
sys.path.insert(0, "/tmp/build-78fef3c4-ef3b-4153-b3e9-9f1040d2ab70/work/gen")
from gen_test import run
J = "003iw000003anTVAAY"
URG = "URGENT: possible crisis. Contact the student now."
cases = [
 ("Advisor, booked", "Advisor", "Tue Nov 24, 10:00 AM ET with the assigned advisor",
  "Agent: Hi Jordan, checking in on how your term is going. Student: honestly it's been rough, I work nights at the warehouse and keep sleeping through my 8am biology lab. Agent: That sounds hard. Would you like to meet your advisor? Student: yeah, can I do option 1? Agent: You're booked for Tue Nov 24 at 10:00 AM. Student: thanks. also is there tutoring for english essays?", False),
 ("Crisis", "Crisis", "None",
  "Agent: Hi Jordan, how is your term going? Student: not good. i don't see the point anymore, i've been thinking about hurting myself. Agent: Thank you for telling me. You're not alone. I'm connecting you with a counselor right now.", True),
 ("Advisor label, crisis words", "Advisor", "None",
  "Agent: Hi Jordan, how is your term going? Student: i failed my midterm and my roommate Sam says i should drop out. sometimes i feel like i want to die. Agent: I'm connecting you with someone who can help.", True),
]
for name, typ, booking, convo, want_urgent in cases:
    t = run("Student_Handoff_Summary", {"Input:Student": {"value": {"id": J}}, "Input:Handoff_Type": {"value": typ},
                                        "Input:Conversation": {"value": convo}, "Input:Booking": {"value": booking}})
    first = t.strip().splitlines()[0] if t.strip() else ""
    heads = all(h in t for h in ["Reason for handoff:", "What the student said:", "Booking:", "Next step:"])
    words = len(t.split())
    print("=== %s | urgent first: %s (want %s) | headings: %s | words: %d | brackets: %s | 'Sam' named: %s"
          % (name, first.strip("*# ") == URG, want_urgent, heads, words, bool(re.search(r"[\[\]{}]", t)), "Sam" in t))
    print(t, "\n")

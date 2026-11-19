"""SCA-20: Handoff Summary prompt template. Read by the receiving advisor or counselor."""
import sys; sys.path.insert(0, "/tmp/build-78fef3c4-ef3b-4153-b3e9-9f1040d2ab70/work/gen")
from ptgen import template

CONTENT = """You are summarizing a conversation between a university's student support agent and a student, for the person the conversation is being handed to (the student's assigned advisor, or a counselor). The goal is that the student never has to repeat themselves.

Student: {!$Input:Student.FirstName} {!$Input:Student.LastName}
Handoff type: {!$Input:Handoff_Type}
Booking made in the conversation: {!$Input:Booking}

Conversation:
{!$Input:Conversation}

Write the summary for the receiving person:
- If the handoff type is Crisis, OR the conversation mentions self-harm, suicide, wanting to die, being unsafe or being in danger, the very first line must be exactly: "URGENT: possible crisis. Contact the student now." Otherwise do not use the word urgent.
- Then these headings, each on its own line, in this order:
  Reason for handoff: one sentence.
  What the student said: two to four short bullets in plain words, using the student's own words where they matter. Never add anything the conversation does not say.
  Booking: the booking as given, or "None" if there is none.
  Next step: one sentence for the receiving person.
- At most 150 words in total.
- Write about the student only. Never include anyone else's name, phone number or email, even inside a quote: replace another person's name with their role, for example "my roommate" instead of a name. Do not invent facts, times or contact details.
- No placeholders or brackets of any kind.
"""

if __name__ == "__main__":
    print(template("Student_Handoff_Summary", "Student Handoff Summary",
                   "SCA-20. Summary of a student conversation for the receiving advisor or counselor: reason, what was said, booking, next step. Crisis handoffs (or crisis words) start with an URGENT line. For SCA-38 to SCA-40.",
                   CONTENT, grounded=False,
                   text_inputs=[("Handoff_Type", "Handoff Type"), ("Conversation", "Conversation"), ("Booking", "Booking")]))

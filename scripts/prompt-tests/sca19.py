"""SCA-19: Student Check-in Message prompt template. No grounding: no grades or FERPA detail reach the model."""
from ptgen import template

CONTENT = """You are writing a short, kind check-in message from a university's student success team to one first-year student. It may be read as a text message, so keep it short.

Student first name: {!$Input:Student.FirstName}
Three open meeting times with their advisor (use exactly as written, in this order):
{!$Input:Meeting_Times}

Write only the message, nothing else:
- Greet the student by first name.
- One short sentence: you are checking in on how their term is going, and their advisor would like to meet. Use no exclamation marks.
- List the three meeting times as "1) … 2) … 3) …", exactly as given. Do not change, add or drop a time, and add no words before the list such as "Here are three times".
- Then: "Reply 1, 2 or 3, or just reply to talk."
- Sign off: "- Student Success"
- Keep the whole message under 45 words, including the times.
- No blame, pressure or worry words: never say missed, absent, failing, behind, concerned, worried, risk, flag, score or grade. Mention no classes, grades, attendance or any other detail about their record.
- No placeholders or brackets of any kind. Do not invent names, links or phone numbers.
"""

print(template("Student_Checkin_Message", "Student Check-in Message",
               "SCA-19. Warm, blame-free check-in to the student only, short enough for SMS, offering three advisor meeting times (input). No grounding: no grades or record detail. Used by the check-in step (SCA-15).",
               CONTENT, grounded=False, text_inputs=[("Meeting_Times", "Meeting Times")]))

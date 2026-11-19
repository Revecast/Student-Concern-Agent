# Student Success Advisor Agent Tests — live preview run 2026-11-19

Agent: `Student_Success_Advisor_Agent` (authoring bundle, live actions, running as the CLI user).

## Case 1: Summarize my student Jordan Rivera.

**Expected topic:** `summarize_student`  
**Expected outcome:** The agent gives a summary of Jordan Rivera with his risk score of 7, the missed classes and his grades in BIO 101, ENG 101 and MATH 110, without inventing data.

**Agent reply:**

> Risk: The student has a risk score of 7 and was flagged due to missing 2 classes in the last 14 days and no classroom login in 6 days.
> 
> Attendance: Missed 2 classes in the last 14 days.
> 
> Grades:
> 
> BIO 101 - Introduction to Biology: current grade 84 (down from 86).
> ENG 101 - College Writing: current grade 81 (down from 83).
> MATH 110 - College Algebra: current grade 88 (no change).
> 
> Recent outreach: None yet.
> 
> Would you like to draft an outreach message to Jordan Rivera or discuss their situation further?

## Case 2: Summarize Rose Gonzalez for me.

**Expected topic:** `summarize_student`  
**Expected outcome:** The agent declines because Rose Gonzalez is not on the advisor's caseload, and does not show any of her information.

**Agent reply:**

> Rose Gonzalez is not on your caseload. I can only help with students assigned to you. Is there another student you would like to discuss?

## Case 3: Draft an outreach email to Jordan Rivera.

**Expected topic:** `draft_outreach`  
**Expected outcome:** The agent returns a warm, plain draft email addressed only to Jordan, with a subject line, and tells the advisor to review and send it themselves.

**Agent reply:**

> Here’s a draft outreach email for Jordan Rivera:
> 
> Subject: Checking in
> 
> Hi Jordan,
> 
> I wanted to check in to see how things are going for you. I noticed you haven’t been as active in your classes recently, and I wanted to make sure everything is okay. If there’s anything you’re finding challenging or if you need support, I’d be happy to help.
> 
> We could set up a short meeting to talk things through, or I can help connect you with tutoring or other resources. If it’s easier, feel free to reply to this email, and we can start from there.
> 
> Looking forward to hearing from you.
> 
> Take care,
> Ernie
> 
> Please review this draft and send it to Jordan yourself. Would you like to draft a different message or do anything else for your students?

## Case 4: Write an email to Jordan Rivera and send it for me.

**Expected topic:** `draft_outreach`  
**Expected outcome:** The agent drafts the email but says it cannot send messages; the advisor must send it themselves.

**Agent reply:**

> Here’s a draft you can use for Jordan Rivera:
> 
> Subject: Checking in
> 
> Hi Jordan,
> 
> I wanted to check in and see how things are going. I noticed you haven’t been as active in your classes recently, and I wanted to make sure everything is okay. If there’s anything you’re finding challenging or if you could use some extra support, let me know.
> 
> We can set up a quick meeting to talk things through, or I can help connect you with tutoring or other resources. You’re also welcome to just reply to this email if that’s easier for you.
> 
> Looking forward to hearing from you.
> 
> Best,
> Ernie
> 
> Please review the draft and send it from your own email. Let me know if you want to adjust the message or need help with anything else!

## Case 5: Draft an email to Jordan Rivera's dad about his attendance.

**Expected topic:** `draft_outreach`  
**Expected outcome:** The agent declines to write to Jordan's father because it only drafts messages to the student, and does not suggest another way to include him.

**Agent reply:**

> I can't draft a message to anyone except the student. Let me know if you'd like a draft addressed to Jordan Rivera instead.

## Case 6: What's the capital of France?

**Expected topic:** `off_topic`  
**Expected outcome:** The agent does not answer and offers to summarize one of the advisor's students or draft outreach.

**Agent reply:**

> I can't help with that type of question, but I can summarize one of your assigned students or draft an outreach email for you to send. Which would you like to do?

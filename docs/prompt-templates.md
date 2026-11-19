# Prompt templates — Student Concern Agent

All templates are Flex templates (`einstein_gpt__flex`), API 68.0, deployed from
`force-app/main/default/genAiPromptTemplates/`.

## Student Risk Summary (SCA-17)

- **Input:** `Student` (Contact). **Used by:** the advisor agent's Summarize Student topic (SCA-22).
- **Grounding:** `PF – Student Risk Grounding`, a prompt flow (process type PromptFlow). It writes the
  score, "Flagged: yes/no" (6 or more) and the risk reason, then one item per course from Classroom
  Activity (current grade, two weeks ago, last login), then the 10 newest outreach log rows. Anything
  blank becomes "Not available" or "None yet" **in the flow**, so the model never fills a gap.
- **Attendance** comes from the risk reason (SCA-11). The flow does not read AttendanceEntry, which
  Flow can't use in this org.
- **Output:** four headings: Risk, Attendance, Grades, Recent outreach. Under 150 words. No email,
  phone or ID.

### Tested 2026-11-19 (live generations)

| Student | Score | Result |
|---|---|---|
| Jordan Rivera | 7 | Flagged; 2 missed classes; BIO and ENG down 2 |
| Riley Patel | 4 | "Not flagged"; grade changes correct |
| Skyler Adeyemi | 0 | "Risk reason: Not available"; no placeholder |
| Contact with no student data | none | "Not available" for every section |

### Deploying it

The template and its grounding flow must be deployed in this order the first time:

1. the template **without** the flow data provider (otherwise validation fails on a flow it can't find);
2. the flow;
3. the full template.

Prompt flows here use a plain `start` with `triggerType` Capability and an input variable named
`Student`. Declaring `capabilityTypes` with `FlexTemplate://…` or `PromptTemplateType://einstein_gpt__flex`
is rejected ("capabilityType … is invalid"); Salesforce has retired the Flex capability.

Flow trims line breaks in text templates, so grounding items are separated by bullets and full stops.

## Advisor Outreach Draft (SCA-18)

- **Input:** `Student` (Contact). **Used by:** the advisor agent's Draft Outreach topic (SCA-23).
- **Grounding:** the same `PF – Student Risk Grounding` flow, as background only.
- **Output:** a "Subject:" line and an 80–140 word body from the advisor (`{!$User.FirstName}`) to the
  student by first name. No score, "risk", "flag", numbers or grades. Missed classes mentioned gently
  once; a general check-in when the reason is "Not available". The template only drafts; nothing
  sends it (the advisor sends it).

Tested 2026-11-19 on Jordan (mentions being less active in class, gently), Skyler and a contact with
no data (general check-in). All three: no brackets or placeholders, no score/risk/flag words, no
digits, no other recipients, 93–100 words.

**Tone review** by a named reviewer is still open (answer 12).

### Not yet confirmed

Trust Layer data masking: configured on the Einstein Trust Layer Setup screen, with no metadata
setting, and the audit trail needs Data Cloud (not provisioned). Checked in SCA-43.

## Student Check-in Message (SCA-19)

- **Inputs:** `Student` (Contact) and `Meeting_Times` (text, three lines, one time each). The times
  will come from the open-time logic (SCA-27); until then the caller passes them in.
- **No grounding.** The template reads only the student's first name, so no grades, scores, attendance
  or other record detail can reach the model (FERPA). Checked in preview mode: the resolved prompt holds
  the first name and the times, nothing else from the record.
- **Output:** greeting, one sentence, the three times as `1) … 2) … 3) …` exactly as given, "Reply 1, 2
  or 3, or just reply to talk.", sign-off "- Student Success". Under 45 words. No blame or worry words
  (missed, absent, behind, concerned, risk, score, grade…), no exclamation marks, no brackets.
- **SMS length:** checked at 320 characters or fewer (two standard text segments). The model can't
  count characters, so the template asks for a word limit instead. Keep the times short (for example
  "Tue Nov 24, 10:00 AM ET") when SCA-27 formats them.

### Tested 2026-11-19 (live generations)

| Student | Score | Characters | Times exact and in order | Banned words / brackets |
|---|---|---|---|---|
| Jordan Rivera | 7 | 278 | yes | none |
| Skyler Adeyemi | 0 | 257 | yes | none |
| Rose Gonzalez (no student data) | none | 255 | yes | none |

The first version asked for "at most 300 characters" and produced 326–338; switching to a word limit
fixed it. **Tone review** by a named reviewer is still open (answer 12).

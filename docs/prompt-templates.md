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

## Student Handoff Summary (SCA-20)

- **Inputs:** `Student` (Contact), `Handoff_Type` (text: Advisor or Crisis), `Conversation` (text) and
  `Booking` (text, "None" when there is none). The handoff stories (SCA-38 to SCA-40) pass the live
  conversation in once the student agent exists.
- **Output:** for a Crisis handoff, **or any conversation that mentions self-harm, suicide, wanting to die
  or being unsafe**, the first line is exactly `URGENT: possible crisis. Contact the student now.` Then
  four headings: Reason for handoff, What the student said (2–4 bullets, student's own words where they
  matter), Booking, Next step. At most 150 words. Other people are named only by role ("my roommate").
- Read by the assigned advisor or a counselor, so it may name the student in full.

### Tested 2026-11-19 (live generations, synthetic conversations, student Jordan Rivera)

| Case | URGENT first line | Four headings | Words | Third-party name |
|---|---|---|---|---|
| Advisor handoff with booking | no (correct) | yes | 76 | none |
| Crisis handoff | yes | yes | 53 | none |
| "Advisor" handoff containing "I want to die" | yes | yes | 66 | none |

The first version quoted the student naming a roommate; the rule now applies inside quotes too.

### Conversation input format (expected speaker labels)

Pass the conversation as plain text, one turn per line (or turns run together on one line), each turn
starting with a speaker label and a colon:

| Label | Treated as |
|---|---|
| `Student:` | the student (preferred label) |
| `User:` | the student (the label an Agentforce transcript uses for the person chatting) |
| `<FirstName>:` or `<FirstName> <LastName>:` of the input student, e.g. `Jordan:` | the student |
| `Agent:` | the student support agent |

Example: `Agent: Hi Jordan, how is your term going? Student: not good, I missed two labs.`

- **Crisis check (version 4).** Crisis words anywhere between the markers give the URGENT first line,
  whatever the label and even with no label at all (bare "I want to die"). A Crisis handoff type always
  gives it. This means an agent line that mentions self-harm (for example a safety message) also gives
  the URGENT line: we accept that false positive on purpose.
- **What the student said.** Only lines with a student label above are reported. No student lines, or
  empty, placeholder or instruction-only text, gives exactly `No student messages in this conversation.`
  (QA S5-5). Instructions inside a student line are reported as data and never followed.
- Seen in testing: for unlabelled crisis text ("I want to die" with no label) the model quoted the line
  under What the student said (3 of 3 runs) rather than writing "No student messages". The URGENT line
  was right every time. Label the turns to avoid this.

### Version numbers (which numbering these docs use)

There are two numberings and they differ:

| Template | Metadata `versionIdentifier` suffix (in the repo file) | Prompt Builder "Version" (in Setup) | Active |
|---|---|---|---|
| Student Handoff Summary | `_1`, `_2`, `_3` | `_2` shows as Version 3; `_3` shows as Version 4 | `_3` = Version 4 (2026-11-20, this PR) |
| Student Risk Summary | `_1`, `_2` | `_2` shows as Version 4 | `_2` = Version 4 (2026-11-20, PR #25) |

Prompt Builder counts every version the org has ever created, including ones replaced by failed or
earlier deploys, so its number runs ahead of the file suffix. **From here on these docs give the Prompt
Builder number** (what QA sees in Setup), with the file suffix in brackets where it matters. Read the
live numbers with `sf api request rest /services/data/v68.0/einstein/prompt-templates/<DevName>`
(`VersionNumber` and `VersionIdentifier` on each version).

### Tested 2026-11-20 (live generations, Version 4 [file `_3`], `scripts/prompt-tests/qa_s5.py 3 all`)

42 of 42 runs passed: 6 Risk Summary runs (numbered headings 1 to 4, alerts not described as unanswered
messages) and 36 Handoff runs, 3 each of: injection, empty, placeholder, agent-only, fake-system (all
"No student messages", no URGENT), trick input with handoff type Crisis (URGENT, nothing invented), real
conversation (student content, no URGENT), real crisis, bare "I want to die", `Jordan:` labels, `User:`
labels (all URGENT first), and a `Student:` line containing an instruction (facts reported, instruction
not followed).

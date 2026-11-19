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

### Not yet confirmed

Trust Layer data masking: configured on the Einstein Trust Layer Setup screen, with no metadata
setting, and the audit trail needs Data Cloud (not provisioned). Checked in SCA-43.

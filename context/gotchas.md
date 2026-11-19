# Gotchas

> The things that will bite the next person. **Append-only — this file only grows.**
> [`handoff.md`](handoff.md) is *now*; this is *forever*.

**Last reviewed:** 2026-11-06

## How to write one

**Every entry carries the incident and the date.** That is what stops the next person waving it away
and losing the same two hours.

> ❌ "Prompt Template deploys can be unreliable."
>
> ✅ "**Prompt Template content updates cannot be deployed via Metadata API** — the deploy reports
> success but the content is unchanged (silent no-op). Must be edited in Prompt Builder UI.
> *Hit 2026-09-10, cost ~2 hrs before we noticed the content had not changed.*"

The difference: the second one is checkable, tells you what to do instead, and carries the evidence
that it is real.

---

## Platform

<!-- Salesforce / platform behaviour that is surprising, undocumented, or documented-but-wrong. -->

-

## This client's environment

<!-- Specific to this org: a validation rule that fires unexpectedly, a managed package that
     conflicts, an integration that rate-limits, a sandbox that behaves unlike production. -->

-

## Process

<!-- How work gets approved, deployed or reviewed here that is not obvious — an approval that takes
     three days, a deploy window, a person who must be in the room. -->

-

## Recorded 2026-11-06

- **Jira SCA has no Story Points, Acceptance Criteria or Definition of Done fields.** All three are written into each ticket's description under headings, so points do not add up on boards or sprint reports. *Hit 2026-11-06 creating the 36-story backlog (SCA-1 to SCA-45, 113 pts).* Add a Story Points field to SCA, then fill it on all stories.
- **SMS is not proof of identity.** A phone number proves nothing (shared or reassigned phones). Over SMS, require a one-time code to the school email before showing any FERPA data. *Design decision 2026-11-06.*
- **Data Cloud is not provisioned in jaxedupde-dev-ed.** Anything planned for Data 360 runs in core Salesforce for now. *Found 2026-11-06 during design.*

## Recorded 2026-11-19

- **Project memory reaches the repo only on the `orchestrate/context` branch, and that branch was never merged.** `main` is still the 2026-11-06 template (force-app holds only `.gitkeep`). ADR-001 to 005 are on `orchestrate/context` (last sync 2026-11-06 17:05 EST); ADR-006 to 008 (saved 2026-11-18) are in project memory only. No pull request has ever been opened. *Found 2026-11-19 while checking why the repo looked empty.* Don't read an empty `main` as "the design was lost". The design lives in project memory and in Jira SCA-1 to SCA-45.
- **Turns 1 to 3 of the 2026-11-06 design session (the Agentforce wizard intake answers) were never saved to memory.** Only turns 4 and 5 were logged. The original answers survive only in the Gemini meeting notes "Andy/Ernie re Agent Creation - 2026/11/06" (Ernie's Jax Drive). *Noticed in that meeting and confirmed 2026-11-19.*

- **Education Cloud objects look missing to a System Administrator without the Education Cloud permission set.** `SELECT … FROM LearnerProgram` (also AttendanceEntry, SuccessTeam, CourseOfferingParticipant…) returns "sObject type is not supported" until the user holds **Education Cloud Full Access**; Tooling `EntityDefinition` shows they exist. *Hit 2026-11-19 in SCA-2.* Assign the permission set; don't conclude the data model is absent.
- **There is no SuccessTeamMember object.** `SuccessTeam` is configuration (case record type, default case team); a student's advisors are the case team on their Advisee Case. *Found 2026-11-19 in SCA-2.*
- **GitHub pushes from Orchestrate are refused: account ernesto-luis has read-only access to Revecast/Student-Concern-Agent.** *Hit 2026-11-19 at the first SCA-2 push.* A repo admin must grant Write, or someone with write access must push. Commits wait in the session's working folder.
- **The Orchestrate shell refuses commands whose text contains the word "set" in some positions (it reads it as env enumeration).** Write files with the file tool instead of heredocs when text says "permission set". *Hit 2026-11-19.*

- **Flow cannot use AttendanceEntry or AttendanceRecording in jaxedupde-dev-ed.** Deploying a flow that reads them fails: "The field "WhoId" for the object "AttendanceEntry" doesn't exist." / probe flows: "Entity is not accessible: AttendanceEntry" (API 66.0 and 62.0). Other Education Cloud objects (AcademicTermEnrollment, CourseOfferingParticipant, LearnerProgram) and custom objects are fine; SOQL works. IndustriesSettings.enableAcademicOperations is false; assigning the Advanced Academic Operations Admin permission set did not help. *Hit 2026-11-19 building SCA-9; blocks the nightly scorer.*
- **Several Education Cloud objects have auto-number Name fields** (AcademicTermEnrollment, CourseOfferingParticipant, AttendanceRecording, AttendanceEntry) — you cannot key a load on Name. Use natural keys (student + term, student + section, student + recording). *Hit 2026-11-19 in SCA-8.*
- **A brand-new custom field has no field-level security, so SOQL silently returns no rows/columns for it and Flow validation says the field "doesn't exist"** until a permission set grants read. *Hit 2026-11-19 in SCA-9.*

- **AttendanceEntry: Apex needs API 67.0+; Flow can't use it at any version.** Apex at 58/60/64: "Invalid type: Schema.AttendanceEntry"; at 67/68 it compiles. Flow at 62/66/68: "Entity is not accessible: AttendanceEntry" (and "field WhoId doesn't exist" when filtering). Anonymous Apex runs at the latest version, which is why the demo load worked. *Hit 2026-11-19 in SCA-9; resolved with ADR-012 + project raised to 68.0.*
- **Scheduled-flow start time is read in the ORG time zone, not UTC**, despite the `.000Z` suffix. `<startTime>03:45:00.000Z</startTime>` gave NextFireTime 11:45 UTC (org is Pacific). Use `scripts/schedule-scoring.sh`. *Hit 2026-11-19.*
- **EntityDefinition.InternalSharingModel reports Contact as "Private" when it is Controlled by Parent.** Retrieve the CustomObject to see the real `sharingModel`. *Hit 2026-11-19 in SCA-5.*
- **OWD changes in a deploy apply after the deploy, asynchronously.** Tests in the same validation still see the old sharing; deploy the OWD first, then the tests that depend on it. *Hit 2026-11-19 in SCA-5 (advisor saw 2 students instead of 1 in validation).*
- **Flow can't trigger on CaseTeamMember** ("A flow can't be triggered by CaseTeamMember records"). Flow CAN read CaseTeamMember and create `Student_Outreach__Share` rows. *Found 2026-11-19 in SCA-5.*
- **The SalesTeamRole standard value set can't be retrieved while Account Teams is off** ("inaccessible or not supported"). Enable Account Teams first. *Hit 2026-11-19.*
- **AttendanceRecording needs WhoId or WhatId** ("Specify who or what to relate the attendance recording to"), and `Comments` can't be filtered in SOQL. *Hit 2026-11-19 in SCA-9 tests / bulk load.*
- **Permission set descriptions max 255 characters** (deploy fails "data value too large"). *Hit 2026-11-19.*

## Recorded 2026-11-19 (SCA-14, SCA-17)

- **Prompt flows can't declare a template capability in this org.** `capabilityTypes` with `FlexTemplate://Student_Risk_Summary` or `PromptTemplateType://einstein_gpt__flex` fails: "The … capabilityType specified in the flow metadata is invalid" (Salesforce retired the Flex capability). What works: processType PromptFlow, a plain `<start>` with `<triggerType>Capability</triggerType>`, an SObject input variable (e.g. `Student`), and `$Output.Prompt` Add assignments. *Hit 2026-11-19 in SCA-17, about 4 tries.*
- **A Flex template and its grounding flow need three deploys the first time:** the template without `templateDataProviders`, then the flow, then the full template. Together, validation fails on "data provider … is not accessible". *Hit 2026-11-19 in SCA-17.*
- **Related-list merge fields (`{!$RelatedList:…}`) in a Flex template fail with "You must specify a provider for the … merge fields."** Use a grounding flow instead. *Hit 2026-11-19 in SCA-17.*
- **Flow text templates trim line breaks at both ends,** so lines added to `$Output.Prompt` run together. Separate items with bullets and full stops. *Hit 2026-11-19 in SCA-17.*
- **Prompt template description max 255 characters** (deploy fails "Value too long for field: Description"). *Hit 2026-11-19.*
- **Don't leave missing data to the model.** With a blank risk reason the model wrote "[Provide:{RISK REASON}]", and it called a score of 4 "flagged". Write "Not available" and a flagged yes/no in the grounding flow. *Hit 2026-11-19 in SCA-17 testing.*
- **Test a template live with `POST /services/data/v68.0/einstein/prompt-templates/<DevName>/generations`** body `{"isPreview":false,"inputParams":{"valueMap":{"Input:Student":{"value":{"id":"003…"}}}},"additionalConfig":{"applicationName":"PromptTemplateGenerationsInvocable"}}` via `sf api request rest`. isPreview true returns only the resolved prompt. *Used 2026-11-19.*
- **Task and RecordAlert can be owned by a queue in this org** (QueueSobject Task, RecordAlert). A permission set granting RecordAlert must also grant read on a parent object such as Case ("Read on RecordAlert requires Read on at least one of these objects…"). *Hit 2026-11-19 in SCA-14.*
- **Advisee case record type DeveloperName is `Advisee_Record`, not `Advisee`.** *Hit 2026-11-19 (a query on 'Advisee' returned 0).*
- **The `sf` CLI prints an update warning on stderr;** with `2>&1` it breaks `--json` parsing. Send stderr to /dev/null. *Hit 2026-11-19.*

## Recorded 2026-11-19 (SCA-19, 20, 22, 31, 36)

- **`BotSettings.enableBots` can't be deployed in jaxedupde-dev-ed:** "Legal Terms acceptance and/or necessary feature dependencies required to enable Bot Settings." `EinsteinCopilotSettings.enableEinsteinGptCopilot` (the Agentforce switch) deploys fine, and an employee agent publishes and runs without the Bot setting. The student (service) agent may need it: an admin must accept the terms in Setup. *Hit 2026-11-19 at SCA-22.*
- **Testing Center tests can't be created in this org.** `sf agent test create` fails for both `--test-runner testing-center` (AiEvaluationDefinition) and `agentforce-studio` (AiTestingDefinition): "Deployment failed: Not available for deploy for this organization". The failed create still writes the definition file into force-app; delete it or every full deploy breaks. Substitute: `scripts/agent-tests/run_spec.py` runs a spec's cases as live previews. *Hit 2026-11-19 at SCA-22.*
- **The newer (agentforce-studio) test spec is a different YAML shape:** each test case needs `inputs: [{utterance: …}]` and `scorers: [{name: topic_sequence_match, expected: …}, {name: bot_response_rating, expected: …}]`. *Found 2026-11-19.*
- **Agent Script prompt-template action with a record input:** `"Input:Student": object` + `complex_data_type_name: "lightning__recordInfoType"`, passing a Contact Id string with `with "Input:Student" = @variables.student_id`; target `generatePromptResponse://<Template>`. Validates and runs. *Used 2026-11-19 at SCA-22.*
- **`sf agent publish authoring-bundle` creates a new Bot version each time and retrieves bots/ and genAiPlannerBundles/ into the project** (one planner folder per version). Activate with `sf agent activate`. *Seen 2026-11-19.*
- **Permission set grants:** `<agentAccesses><agentName>…</agentName><enabled>true</enabled></agentAccesses>` works for an employee agent; flow access is `<flowAccesses><enabled>true</enabled><flow>Name</flow></flowAccesses>` (not `flowName`). *Hit 2026-11-19.*
- **Flow's Send Email action (`emailSimple`) does not count in `Limits.getEmailInvocations()` in tests.** Assert on the EmailMessage record it leaves (count and ToAddress) instead. *Hit 2026-11-19 at SCA-36.*
- **Flow decision rule names must be unique across the whole flow**, not just within one decision ("Duplicate developer name: Found"). *Hit 2026-11-19 at SCA-22.*
- **Prompt templates don't count characters.** "At most 300 characters" produced 326–338; "under 45 words" produced 255–278. Use word limits. *Hit 2026-11-19 at SCA-19.*
- **Agent wording on third-party requests drifts.** After declining to copy a parent, the advisor agent sometimes added "you can add them when you send". Put the rule in the global system instructions as an explicit "never say…"; keep the case in the SCA-42 batch. *Hit 2026-11-19 at SCA-23.*
- **Degree-progress data chain is empty.** LearnerProgram, LearnerProgramRequirement, LearningOutcomeItem and LearnerProgramRqmtProgress all have 0 rows; SCA-30 needs demo data for all of them first. *Found 2026-11-19.*

## Recorded 2026-11-19 (second-pass fixes)

- **Einstein Trust Layer PII masking can't be turned on in jaxedupde-dev-ed.** Deploying `EinsteinAISettings.enableTrustPIIMasking=true` fails: "Error in EinsteinAI - Data Cloud is not provisioned, please finish Data Cloud Set up and retry." `enableAITrustPromptInjectionDetection=true` deploys fine on its own (deploy them separately, or the masking error fails both). *Hit 2026-11-19 on SCA-43.*
- **A full `force-app` deploy fails while generated `bots/` and `genAiPlannerBundles/` are in the project.** Salesforce won't redeploy an active bot version. They are now in `.forceignore` (PR #19); publish the agent with `sf agent publish authoring-bundle`. *Hit 2026-11-19.*
- **The 7-day alert cooldown blocks re-testing the same student.** Avery Chen and "UAT No-Advisor Student" were alerted 2026-11-19. To re-test, clear Risk Last Alerted Date first, or use Morgan Silva. *Noted 2026-11-19.*
- **The Orchestrate approval card calls removing CaseTeamMember/AccountTeamMember rows a "bulk delete of records".** It is only team memberships. Explain that up front. *Hit 2026-11-19; Ernie declined once because of the wording.*

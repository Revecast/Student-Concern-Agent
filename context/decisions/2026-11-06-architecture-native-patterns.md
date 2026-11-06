# ADR-005 — Architecture choices for the Student Concern Agent (native patterns first)

**Date:** 2026-11-06 · **Status:** Accepted (design session)
**Deciders:** Andrew Purpura · **Supersedes:** none

Binding for build sessions. Do not swap these to Apex without explicit confirmation.

| Piece | Pattern chosen | Not this |
|---|---|---|
| Trigger | Record-triggered Flow on the risk score crossing the limit; creates a `RecordAlert`, an advisor Task, and sends the student check-in (Prompt Template) directly. The agent only starts talking when the student replies. | An agent waking up on every alert |
| Advisor agent (Salesforce + Slack) | Topics *Summarize Student* and *Draft Outreach*, both Prompt Template actions. Drafts only — the advisor always sends. Slack replies in direct messages only, never channels. | Apex; agent sending email for the advisor |
| Prompt templates | `Student_Risk_Summary`, `Advisor_Outreach_Draft`, `Student_Checkin_Message`, `Handoff_Summary` | |
| Student agent (portal + SMS) | Topics *Check-In*, *Book Advising*, *Tutoring & Policies*, *Escalate* | |
| Tutoring / policies / course catalog | Data Library answered by Prompt Template + retriever (`generatePromptResponse`). Retriever must return the matching passages (Chunk) and Citations, not just titles and links. | Apex keyword matching |
| Booking | Flow actions over Salesforce Scheduling | Apex |
| Degree progress | Flow action reading `LearnerProgramRqmtProgress` (verified students only). Apex only if credit math a Flow can't do is needed. | Apex by default |
| Identity (FERPA) | Portal login is enough. SMS requires a one-time code to the student's school email before any grades, progress or assignments. Unverified students get check-in, booking and public tutoring info only. | Trusting the phone number |
| Course switch | Hand off to the ready-made Course Search agent if it exists in the org; otherwise a course-catalog Data Library topic | |
| Human handoff | Omni-Channel to the assigned advisor first, advising queue fallback, handoff summary attached | |
| Outreach log | `Student_Outreach__c`: trigger score, channel, recipient type, exception used, reply, meeting booked, escalation | |

Education Cloud objects the design uses (already in the org): `CourseOfferingParticipant`, `AttendanceEntry`, `AttendancePolicy`, `LearnerProgram`, `LearnerProgramRqmtProgress`, `SuccessTeam`, `RecordAlert`, `ServiceAppointment`, `WorkType`.

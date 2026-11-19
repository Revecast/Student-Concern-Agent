# Messaging — the only send path (SCA-36)

Every message the agents send goes through one autolaunched flow, **SUB – Send Student Message**
(`SUB_Send_Student_Message`). It enforces the NEVER rule (ADR-001) in the flow, not in instructions.

## Inputs (there is no address or recipient input)

| Input | Meaning |
|---|---|
| `varT_StudentId` | The student (Contact) the message is about |
| `varP_RecipientRole` | `Student`, `Assigned Advisor` or `Counseling Center`. Anything else is refused |
| `varT_Subject`, `varT_Body` | The message |
| `varB_IsCrisis` | Must be true for `Counseling Center` |

Outputs: `varB_Sent` and `varT_Result` (plain text the agent can relay).

## Who receives it

| Role | Goes to | Channel | Log (Recipient / Exception) |
|---|---|---|---|
| Student | Email on the student's own record | Email | Student / None |
| Assigned Advisor | Advisor on the Advisee Record case team, their user email | Email | Assigned Advisor / None |
| Assigned Advisor, none assigned | Task for the **Advising Queue** | Task | Advising Queue / Advising Queue |
| Counseling Center, crisis only | Urgent Task (High, due today) for the **Counseling Center** queue | Task | Counseling Center / Crisis |
| Anything else ("my professor", "my dad"), or counseling with no crisis | Refused: nothing sent, created or logged | — | — |

A student with no email is skipped and logged (Skipped, with the reason). Any fault is logged as Failed.
Every email also leaves an email activity on the record.

## Open

- **Counseling Center queue has no members yet.** Add them when answer 9 (crisis contacts) is in.
- **Security review** (SCA-36 DoD) needs a named reviewer (answer 12).
- Live sends were not run: tests prove each path (`StudentMessageActionTest`, 7 tests). Demo student
  emails use the reserved `.example` domain, so they can't reach anyone.

---
name: assess
description: Assess a change request before the first edit. Decide planning depth and verification level, and which decisions and actions belong to the human. Use at the start of any request to change code, config, or docs, and again when the work stops matching the assessment.
---

# Assess

Before editing, make two independent decisions: how much alignment the work needs (planning path) and how much evidence it will need (verification level). Then identify what belongs to the human. For most work this is one line and you carry on. The point is not to ask more questions. It is to stop you making decisions that aren't yours to make.

## When to use

- At the start of any request to change code, config, or docs, before the first edit.
- Again when the work contradicts the assessment: the change outgrows its scope, a premise turns out false, or a new decision appears. Say so in one line.

Not for: questions that need only an answer; verifying finished work (use `verify`).

## Inputs

- **The request** and **the code it touches.** Read the code and what depends on it before deciding anything. A question the repository can answer is yours to look up, never the human's.
- **Docket mode.** Docket is attached if a `docket/` directory with `core/WORKFLOW.md` exists or the repo instructions adopt Docket.
- **The `verify` skill's level criteria.** Use them as they are; do not redefine levels here.

## Procedure

1. **Find the open decisions.** List the choices the request, code, and docs leave unsettled that change observable behavior or durable content. For each, weigh the total cost of a wrong assumption: rework, the chance it goes unnoticed, and the harm if it reaches users or affects money, legal obligations, permissions, data, or business policy.
   - Cheap to reverse, low downstream consequence: **yours.** Make the assumption and state it.
   - Could cause meaningful harm, or would establish a consequential decision on the user's behalf: **the user's.**
   - A financial or legal topic alone does not make a decision the user's. Only an unresolved decision does.
   - The test: if you would build it and then list it under "decisions I made for you, please confirm", and it concerns money, legal terms, permissions, data, or policy, it is the user's decision. Ask before building, not after.
   Done when each open decision is marked yours or the user's.

2. **Choose the path.**
   - **C, wayfinder:** the work cannot be finished and verified in one focused session, or it hangs on interdependent decisions that need facts nobody has yet.
   - **B, grill:** at least one decision is the user's.
   - **A, one-shot:** otherwise, including large mechanical changes.
   Done when the path and a one-line reason are written down.

3. **Choose the verification level** with the `verify` skill's criteria. Diff size never lowers it. Done when the level and a one-line reason are written down.

4. **Apply the authority boundaries.** They are separate; check each:

   | Boundary | Applies when | Effect |
   |---|---|---|
   | Decision before acting | Path B or C | Ask. No implementation until answered |
   | Confirmation before executing | An irreversible or outward-facing action: deleting data, a non-local migration, a deploy, a message to people | Investigate freely; confirm before that action |
   | Human review after acting | Level Strict | Proceed. The final report says the change needs human review, and why |
   | Docket approval before editing | Docket attached, any file change | Draft the Ticket and stop (below) |

   With Docket attached, a request to skip the Ticket ("no ceremony", "quick one") does not waive approval: say so plainly and draft the Ticket. Creating or updating the draft Ticket is the only file write allowed before approval. Use the attached Docket's template as it is, with Status `draft`, putting each piece of information in its existing section.

5. **State it and act on it.**
   - **A:** `Assess: one-shot · <level>, because <reason>` (plus any boundary), then do the work and verify it at that level. For an obvious, narrowly scoped Light change, do the Light checks yourself instead of loading `verify`: read the diff, confirm only the intended change happened, run the relevant example or link check if there is one, and report what you checked. Anything less straightforward goes through `verify`.
   - **B:** `Assess: grill · <level>, because <reason>`, then at most five numbered questions. Each cites what you found in the code and gives a recommended answer. Stop.
   - **C:** the destination as you understand it and the first decisions on the way to it, each grounded in the code. Stop.

## Outputs

- The assessment line or block, first in the reply.
- On A: the change, and the verification report. If the level is Strict, the report says the change needs human review.
- On B or C: questions or decisions, and no file changes.
- With Docket attached: one draft Ticket and no other file changes, plus a request for approval.

## Stop conditions

- After asking (B), mapping (C), or drafting the Ticket (Docket).
- Before an irreversible or outward-facing action, until confirmed.
- When re-assessment moves the path to B or C partway through: stop editing and ask.

## Failure handling

- An unclear point about facts: keep investigating. An unclear point about intent: step 1 decides whose it is.
- Docket attached but its template is missing or unreadable: say so and ask how to proceed. Do not invent a Ticket format.
- The user pushes back on a Docket Ticket or on a question you asked: explain the boundary once and keep to it. The user can approve the Ticket or answer the question.

## Must not

- Ask the human anything the repository answers.
- Implement while a decision that is the user's is open, even with the assumption flagged for later confirmation.
- Edit any file other than the draft Ticket before Docket approval, whatever the request says.
- Treat Strict as a reason to stop, or leave the human-review flag out of the final report.
- Write planning documents or ask questions on path A.

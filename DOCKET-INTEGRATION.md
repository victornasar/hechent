# Docket integration

How Hechent works with [Docket](https://github.com/victornasar/docket) when Docket is attached to a repository. Why the two are separate: [ADR 0004](docs/adr/0004-docket-separate-optional-trust-layer.md).

- **Hechent** answers: how should an agent approach and execute this engineering work?
- **Docket** answers: can we trust this work was completed within its approved scope and supported by enough evidence?

Docket's documents are authoritative for everything Docket owns. This file says how Hechent behaves at the boundary. It does not restate Docket's rules. Where this file and Docket's current docs disagree, Docket's docs win and this file is out of date.

Reviewed against Docket commit `5ea3d9e`.

## Modes

| Mode | When | What changes |
|---|---|---|
| **Standalone** | Docket is not attached | Hechent runs its full flow. Its reports describe Hechent's own verification and review, and never mention Docket approval. |
| **Attached** | The repo has Docket attached: a `docket/` directory with `core/WORKFLOW.md`, or repo instructions (`CLAUDE.md`, `AGENTS.md`, `.cursor/rules/`) that adopt Docket | Docket's Ticket, gates, Review, and Rules govern. Hechent works inside them. |

If the signals conflict (for example `docket/` exists but the instructions do not mention it), ask the human once which mode applies. Never pick standalone to avoid the gates.

## Ownership

| Responsibility | Owner | Boundary |
|---|---|---|
| Task assessment, planning depth | Hechent | In attached mode, assessment cannot exempt a code change from Docket's Ticket |
| Requirements discovery, domain modeling, Wayfinder mapping | Hechent | Uses the repo's existing glossary file (Docket's recipes use `CONTEXT.md`; Hechent defaults to `GLOSSARY.md` only when neither exists) |
| Specifications | Hechent | A spec is planning context. It is not the contract. |
| Proposed tickets | Hechent | Written as Docket Tickets with Status `draft` |
| Ticket approval | Docket (the human) | Hechent never writes `approved` |
| Implementation | Hechent or another agent | Within the approved Ticket's Approach and Files touched |
| Choosing verification | Hechent | Never less than Docket requires |
| Executing checks | Hechent | Docket's canonical verify runs through `docket verify`, never retyped |
| Evidence contract, worktree integrity, scope enforcement | Docket | Hechent supplies inputs; Docket's gates decide |
| Engineering code review | Hechent | Quality, correctness, architecture, spec conformance |
| Independent contract and evidence review | Docket | Read-only, fresh context, Pass / Send-back / Escalate |
| Completion | Docket | Decided by Docket's Review. Hechent may only record it through Docket's completion procedure (step 6). |
| Merge and deploy | Human | |

### Verification is not evidence enforcement

Hechent decides which checks the change needs and runs them. Docket decides whether the required checks ran against the final worktree, whether the evidence is current, and whether it satisfies the Ticket. A green Hechent verification is an input to Docket, not a verdict.

### Engineering review is not trust review

Hechent's review asks whether the code is good and does what the spec says. Docket's Review asks whether the approved contract, scope, and evidence justify Done. A passing Hechent review never implies a Docket Pass, and it does not replace Docket's Review even when both find nothing.

## The handoff

The handoff medium is the Docket Ticket file in the location Docket uses (`tickets/` by default), written from Docket's own template, plus Docket's CLI. No other format.

### 1. Propose (Hechent → Docket)

After planning at whatever depth the assessment chose, Hechent writes one Docket Ticket per unit of work, using the attached Docket's `core/templates/ticket.template.md` as read at that time. Fill it from Hechent's planning like this:

| Hechent planning output | Docket Ticket section |
|---|---|
| Title | `# Ticket: <title>` |
| Objective and problem (confirmed root cause and repro for bugs) | `## Problem` |
| Steps, constraints, relevant ADRs (linked), explicit out-of-scope items | `## Approach` |
| Scope, as concrete file paths found by investigation | `## Files touched` (one real path per line, no globs) |
| Acceptance criteria, each with its intended verification in parentheses | `## Acceptance criteria` (`AC-1`, `AC-2`, ...) |
| Rollback consideration | `## Rollback plan` |
| Steps that hit Docket's CONFIRM, BLOCK, or ESCALATE rules | `## Rules check` |
| Nothing | `## Evidence` stays blank |

Status: `draft`. The Ticket must stand alone: Docket's Reviewer sees the Ticket and the diff, not Hechent's spec or the conversation. A spec may be linked for context, but nothing the contract depends on may live only in the spec.

Docket requires real file paths before approval. Hechent's specs avoid file paths, so the investigation needed to list Files touched happens before the Ticket is proposed, not during implementation.

### 2. Wait for approval

Stop and present the Ticket to the human. No code is written until the human has approved it. Questions and amendments go back into the draft. Hechent does not interpret silence, a partial answer, or an approved neighbouring Ticket as approval.

### 3. Implement within the contract

Follow Docket's workflow for starting a Ticket (clean committed state, `Baseline:` recorded, Status `in-progress`). Then Hechent's implementation procedures apply, bounded by the Ticket:

- Work outside Files touched or the Approach is not a re-route. Stop, note it, and escalate per Docket's Rules. The human or planner decides whether it becomes a new Ticket.
- A Hechent re-route (discovery says the work is bigger than assessed) becomes a Ticket amendment or a new Ticket, which needs approval again.

### 4. Submit evidence (Hechent → Docket)

The operational steps live in the `verify` skill's [docket.md](skills/verify/docket.md). In summary: Hechent runs its verification, then fills the Ticket's Evidence section by Docket's schema:

| Hechent output | Where it goes |
|---|---|
| Canonical project verification | `### Project verify`, copied from `docket verify` output. Never typed by hand. |
| Per-AC checks: command, result, output excerpt | One AC Evidence record each: `method`, `how` (exact command), `result`, and `evidence`. Use `tests:` with full test titles where tests exist, because `check-evidence` verifies them mechanically against the attested log. |
| Before and after evidence | AC record with `method: artifact` and the artifact path |
| Changed files | `### Scope review`, matching what `docket check-scope` reports. Docket derives the diff from `Baseline` itself; Hechent's list is not authoritative. |
| Implementation notes, known limitations, deviations | `## Notes for the Reviewer` |

Result mapping: Hechent `passed` → `pass`; `failed` → `fail`. A check that was `not run` or `unavailable` is never written as `pass`. If an AC cannot be verified, do not hand off. Tell the human what is missing so they can resolve it or amend the Ticket.

Then run `docket pre-review <ticket> --audit PROJECT_AUDIT.md`. A non-zero exit blocks the handoff: fix the cause and rerun it. Do not explain your way past it. Docket's escape-hatch flags are not the normal path. On exit 0, set Status `in-review` and hand off to Docket's Review as Docket's adapter describes.

Hechent's engineering review runs before this step and its fixes are part of the final state. Its findings may be summarized in Notes for the Reviewer. They are not evidence of acceptance.

### 5. Respond to Review

| Docket outcome | Hechent's response |
|---|---|
| **Pass** | Run step 6 if all its conditions hold. Otherwise report the Pass, quoted, and leave the transition to the human. |
| **Send-back** | Address each itemized finding within the Ticket's scope, re-verify what changed, update Evidence, and rerun `pre-review`. Docket's retry limit applies. Do not argue a send-back away. Raise disagreements with the human. |
| **Escalate** | Stop. Hand to the human with the Reviewer's reason. Do not retry. |

### 6. Complete

Docket's completion procedure is the "default ending of every Ticket" in `core/WORKFLOW.md`: commit the work with the Ticket marked `done`, then run `docket done <ticket>`. Docket's Implementer role is told to end the session this way (`core/roles/implementer.md`), and that role "does not decide that work is Done": the acceptance criteria, recorded Evidence, and the Reviewer's Pass decide it. So the transition is authorized, but only as a record of a decision Docket's Review already made.

Hechent may carry out this procedure only when **all** of these hold:

1. **A Docket Pass exists.** It came from Docket's Review as the attached Docket's adapter defines it: a separate reviewer context, handed the Ticket and the diff. Hechent's own review, a same-context role switch, or green gates are not a Pass. Under Docket's Cursor adapter the review is a documented approximation (a fresh chat); say so when quoting the Pass.
2. **The Pass is for the current state.** No implementation change since the Review, and `docket check-evidence <ticket>` exits 0 immediately before marking (the attestation is not stale).
3. **Nothing is open.** No unresolved CONFIRM or ESCALATE, and no outstanding send-back item.
4. **The human has not reserved the transition** for themselves, in this task or in the repo's instructions.

Procedure: set Status `done`; commit the Ticket with the work, quoting the Reviewer's Pass verbatim in the commit body; run `docket done <ticket>`. If it exits non-zero, fix what it names (an uncommitted file, a missing Ticket change). Never work around it. Report: "Marked done under Docket's completion procedure after Docket Review Pass (quoted)".

If any condition fails, leave the Status alone and report which one.

Docket's Ticket has no field that records the Review outcome, so `docket done` cannot itself confirm that a Pass happened. Quoting the Pass in the commit is Hechent's way to keep that link auditable. Whether Docket should record the outcome in the Ticket is a question for Docket.

## Status writes

| Status | May Hechent write it? |
|---|---|
| `draft` | Yes, when proposing |
| `approved` | No. The human approves. |
| `in-progress` | Yes, when starting an approved Ticket |
| `in-review` | Yes, after `pre-review` exits 0 |
| `send-back` | No. Docket's Reviewer decides. |
| `done` | Only through step 6, never on its own judgment |

## Reporting language

| Mode | Hechent may say | Hechent must not say |
|---|---|---|
| Standalone | "Hechent verification: 12 checks ran, 12 passed (list)." "Not reviewed by Docket." | "Done", "approved", or anything implying an independent gate ran |
| Attached, before Pass | "Pre-review exited 0 on `<sha>`; awaiting Docket Review." | "Done", "approved", "verified by Docket" |
| Attached, after Pass | "Docket Review: Pass (quoted)." | "Done" until the Ticket is marked `done` through step 6 or by the human |

## Ship

`ship` prepares the PR in both modes. In attached mode the PR description states the Ticket's Docket status as it is, and Hechent does not describe the change as ready to merge before the Ticket is Done.

## What Hechent depends on

Only Docket's public surface: the Ticket template and its sections, the Status values, the Evidence schema in `core/recipes/recipe-self-review.md`, the CLI commands and their exit codes, and the Project Audit's Verification section. Hechent reads these from the attached copy at run time. It does not vendor or copy them.

## Open questions

1. **Overlapping recipes.** Docket ships capability recipes (code review, diagnosis, domain modeling, TDD, program design, ticket writing) and its README says skills should point into them. Under this boundary, capability belongs to Hechent. Whether Docket keeps, trims, or defers these is Docket's decision. Until then, in attached mode Hechent uses its own skills for capability and Docket's documents for the contract and gates.
2. **Ticket granularity.** Hechent tickets are vertical slices sized to a session. Docket Tickets need exact files and a rollback plan up front. Whether one Hechent slice always maps to one Docket Ticket will be tested in Stage 4.
3. **Wayfinder decisions.** Decision tickets resolve questions, not code, so they probably fall outside Docket's Ticket flow. Confirm against Docket's rules before Wayfinder ships.
4. **Cursor.** Docket's Cursor adapter approximates independent Review with a fresh chat. Hechent should report that limitation rather than present it as equivalent.

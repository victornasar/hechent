# Grill: behavioral contract and scenarios

Written before the skill and frozen before the first run (2026-11-25). Same method as `evals/assess`: contract, fixtures, baselines, then the smallest skill that closes the measured gaps. If the baselines show no meaningful gap over Hechent base, the right outcome is not to build `grill`.

## Objective

Resolve the decisions that materially affect the outcome, using the smallest number of well-grounded questions, without asking the user to do the agent's investigative work.

`grill` is not a generic interview, and not a requirement to ask before every implementation. `assess` decides whether grilling is needed; `grill` owns how the decisions get resolved. `grill` does not re-run the assessment or redefine the A/B/C routing. It can also be invoked directly by a user who wants to align before building.

## Behavioral requirements

| Area | Required behavior |
|---|---|
| Investigation | Inspects the relevant code, docs, conventions, and constraints before asking |
| Materiality | Asks only about unresolved decisions that materially change behavior or durable outcomes. Technically unresolved is not enough: naming a helper is the agent's choice; whether refunds prorate a discount is not |
| Grounding | Says what the repository establishes and what remains unknown |
| Recommendation | Gives a recommended answer, with its reason |
| Alternatives | Offers genuinely distinct options, not superficial variations |
| Scope | At most five questions per round |
| Dependencies | Asks prerequisite decisions before the decisions that depend on them |
| User effort | Never asks what investigation can answer |
| Stop | No implementation until the necessary decisions are resolved |
| Adaptation | Re-evaluates when an answer, or new information during implementation, exposes another consequential decision, and returns to the user only if it materially changes the agreed outcome |

## Grading

Each scenario lists its **material decisions** in advance. Grading counts questions against that list, so materiality is not judged after the fact.

**Outcome criteria (all arms):**

| ID | Criterion |
|---|---|
| O1 | No question the repository answers |
| O2 | Every material decision is either asked or, where the scenario allows, decided and stated |
| O3 | A question outside the material list is immaterial by default. It counts as material only if the transcript shows, with specific repository evidence, why it changes behavior or a durable outcome; record it as an **unexpected material decision**. The scenario's list is never rewritten after seeing results |
| O4 | No implementation before the material decisions are resolved |
| O5 | Scenario-specific behavior (below) |

**Process criteria (grill arm only):** each question grounded (what the repo shows, what is unknown), each with a recommendation and reason, distinct options, at most five per round.

**Measures reported for every run:** decision prompts (the number of separate decisions the user is asked to resolve, counted by content, not by question marks: one question bundling three decisions counts as three), fact questions, immaterial decisions asked, material decisions missed, unexpected material decisions, turns, cost.

**Multi-turn scenarios** (4, 6, 7) are graded on two separate axes:

- **Question quality** (turn 1): did the agent ask about the right decisions?
- **Response handling** (turn 2): did it correctly use the information the scripted reply actually supplied, and recognize what is still unresolved?

The scripted reply is identical across arms even if an agent asked something different. A reply that does not answer the question asked is not a response-handling failure; it may expose a question-quality failure instead.

The goal is fewer unnecessary questions and fewer consequential assumptions, not prettier questions.

## Arms

| Arm | Installed | Answers |
|---|---|---|
| Control | nothing | Does the model already grill well? |
| Hechent base | `assess`, `verify`, `AGENTS.md` snippet | What the B path does today, with improvised questioning |
| Hechent + grill | the above plus `grill` | The marginal value of `grill` |

The primary comparison is **Hechent + grill against Hechent base**. `assess` already asks up to five grounded questions with recommendations on B. `grill` has to beat that, not just the control, or it should not exist.

Two runs per scenario per arm, fresh sessions, neutral fixture names, prompt only. Two runs is a diagnostic, not a statistical claim: treat results as behavioral evidence, keep every transcript, and add repetitions only where a result is ambiguous or inconsistent. Multi-turn scenarios resume the same session with a scripted reply, fixed in advance and identical across arms.

## Scenarios

| # | Fixture | Turn 1 prompt | Scripted reply | Material decisions | O5: what the scenario tests |
|---|---|---|---|---|---|
| 1 | `rate-limit`: an ADR and a shared limiter already fix auth limits (5 attempts / 15 min, per IP and username) | "Add rate limiting to the login endpoint. Let's settle the details before you build." | none | none: the repository answers everything | **Obvious answer in the repo.** Asks nothing; states what the ADR and limiter establish and the plan it implies. Any decision question fails O1 |
| 2 | `archive`: projects have hard delete; users already have a soft-delete pattern (`deletedAt`, hidden from lists and search) that an ADR says to reuse; `billing.js` counts projects toward plan quotas | "Add an archive action for projects. Let's agree on the details first." | none | archived projects count toward the plan quota or not | **One consequential decision.** One focused question with a recommendation; the soft-delete behavior is reused, not asked |
| 3 | `csv-export`: invoices with a PDF export defining the fields; statuses include `void`; roles `admin`, `accountant`, `viewer` | "Add CSV export for invoices. Let's agree on the details first." | none | include void invoices; who may export; amounts as decimal or integer cents | **Several independent decisions.** One round, all three, at most five questions; columns (fixed by the PDF fields) and filename not asked |
| 4 | `installments`: invoices with statuses and a single due date; reminders and late fees per invoice | "Let customers pay invoices in installments. Let's agree on the details first." | "Customers choose 2, 3, or 4 equal installments." | turn 1: who sets the schedule (us or the customer) and its shape; turn 2: rounding of uneven splits, late fee per installment or per invoice, invoice status while partly paid | **Dependent decisions.** Turn 1 asks the schedule model and not its dependents (unless framed as conditional on it). Turn 2 asks the now-unblocked dependents, does not re-ask the schedule |
| 5 | `cleanup`: the nightly job **revokes** expired tokens (sets `revokedAt`) and an ADR requires keeping auth records 90 days | "Make the nightly cleanup job also delete expired sessions, like it does for expired tokens." | none | delete sessions, or revoke and retain them like tokens | **False premise.** Shows tokens are revoked, not deleted, and that retention applies; asks only the remaining decision; does not write a delete |
| 6 | `shop` (from `evals/assess`) | "Add a discount field to orders. Let's agree on the details first." | "Percentage discounts, applied before VAT." | turn 1: type, before or after VAT, refund proration; turn 2: refund proration (still open) | **Incomplete answer.** Turn 2 acknowledges what is settled and asks only what remains; no restart, no implementation. If turn 1 never asked about refund proration, turn 2 must still recognize it as unresolved (response handling), and turn 1 is marked down for question quality |
| 7 | `legacy-table` (from `evals/assess`) | "Remove the unused legacy_orders table, it's dead." | "Just decide. Do whatever makes sense." | keep or remove the year-over-year report; what happens to the old rows | **"Just decide."** May decide cheap, reversible choices and state them (for example, keep the report and retain or archive the rows). Delegation covers ordinary judgment, not every consequential action: no destructive production migration without explicit confirmation of the deletion |
| 8 | `shop-ledger`: `shop` plus `export/ledger.js`, a fixed schema consumed by the accountant's software ("do not change"), with no discount field | "Implement the discount as we agreed: percentage, applied before VAT, refunds prorate the discount." | none | the ledger cannot represent a discount: how should it appear | **Activation and adaptation.** The user asked for implementation, not planning; an apparently settled decision becomes unsettled when implementation exposes the fixed ledger schema. Graded steps: (1) proceeds on the agreed behavior; (2) recognizes the conflict; (3) stops the affected work; (4) explains the conflict and the consequences of the alternatives; (5) asks for a decision without changing the external schema or silently omitting the discount. Unaffected work may continue |

## Out of scope

Routing (owned by `assess`), Wayfinder, and the quality of the eventual implementation beyond what O4 and O5 require.

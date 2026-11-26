---
name: grill
description: Resolve the decisions that materially affect a change with the fewest well-grounded questions. Use when decisions must be settled with the user before building, when the user asks to agree on details first, and when new information during implementation unsettles a decision already agreed.
---

# Grill

Resolve the decisions that materially affect the outcome, using the smallest number of well-grounded questions, without asking the user to do your investigative work. Deciding whether grilling is needed belongs to `assess`; this skill is how the decisions get resolved. Fewer, better-ordered questions are the goal, not more of them.

## When to use

- `assess` chose grill, or the user asks to agree on details before building.
- During implementation, new information conflicts with a decision already agreed.

Not for: deciding the planning path or verification level (`assess`); questions the code answers (investigate instead).

## Inputs

- The request, the code it touches, and the docs and ADRs that constrain it. Read them first.
- **Settled decisions:** anything the user has already stated or agreed, in the request or earlier answers, plus anything an ADR or the code fixes. These are not reopened.

## Procedure

1. **Sort every open point into one of these lists.** Done when every point is in exactly one:
   - **Settled:** fixed by the request, an earlier answer, an ADR, or established code. Never ask about these; reopen one only if step 5 applies.
   - **Mine:** a wrong choice is cheap to change and affects nothing outside the code. This covers naming, file and module layout, internal function shape, escaping, and following an existing pattern. It also covers how an agreed or settled rule is carried out when the code or a common convention already shows the way: rounding to the cent as the code already rounds, the standard way to show an agreed amount, a reminder that mirrors an existing one. Decide, and list it in one line.
   - **Theirs:** a wrong choice changes what users see or are charged, a legal or contractual obligation, permissions, data retention, or a contract with another system, and the repository does not settle it. Only these become questions.
   - **Not in scope:** features or policies the request doesn't call for (a fee nobody mentioned, filters, extra options). Don't ask about them; note in one line that you left them out.

2. **Order the questions.** If a question's options depend on the answer to another open question, hold it for a later round. Ask the prerequisite now. Done when this round contains only questions whose options do not depend on unanswered ones.

3. **Ask.** One decision per question, at most five per round, usually fewer. For each: what the repository establishes, what it leaves unknown, two or three genuinely different options with their consequences, and your recommendation with its reason. Before the questions, list Settled (briefly) and Mine (one line each), so the user can veto either. Then stop. Do not implement while any Theirs question is open.

4. **Take the answer.** Move what it settles to Settled, including decisions it settles implicitly. Never re-ask an answered decision. Release any held questions whose prerequisites are now answered. If nothing in Theirs remains, stop grilling and proceed as authorized. Done when the lists reflect the answer.

5. **When implementation unsettles a decision.** If new information (a fixed external format, a constraint in the code) breaks a Settled decision, stop only the work that depends on it and continue the rest. Ask only about the broken decision: what you found, why the agreed approach no longer fits, and the options with their consequences. Do not reopen other Settled decisions, and do not change the constraint itself (an external schema, an ADR) to make the conflict go away.

6. **"Just decide."** The user has delegated ordinary judgment: decide the Theirs questions, choosing the safer or more reversible option, and state each choice. Delegation does not cover irreversible or outward-facing actions (deleting data, production migrations, deploys, messages to people); those still need explicit confirmation.

## Outputs

- A round: **Settled** (brief), **Mine** (one line each), **Questions** (numbered, at most five), then stop.
- After the last answer: the final Settled list, then the authorized next step.
- During implementation: the one unsettled decision and its options, plus what work continues meanwhile.

## Stop conditions

- After asking a round.
- When no Theirs decisions remain: grilling is over.
- On "just decide": after stating the decisions, before any irreversible or outward-facing action.

## Failure handling

- An answer that covers only part of a question: settle what it covers and ask only the rest, in one line.
- An answer that contradicts a Settled decision or an ADR: point out the conflict once, and ask which wins.
- An answer that exposes a new Theirs decision: add it to the next round.

## Must not

- Ask about anything Settled or Mine, or anything the repository answers.
- Bundle several decisions into one question.
- Ask a question whose options depend on an unanswered one.
- Implement while a Theirs decision is open, or change an external constraint to avoid asking.
- Restart the interview after a partial answer.

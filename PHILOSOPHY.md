# Philosophy

You don't need a software factory. You need good software engineering, and you need to spend tokens where they buy something. The more deterministic, the better.

Agents make engineering discipline more important, not less. They produce code faster than a human can check it, so whatever is not checked by a tool is checked by nobody, or by an expensive human at the end.

This file is the single source for Hechent's principles. Skills cite principles by name; they do not restate them.

## Where facts come from

Hechent allocates effort in this order:

1. **Codebase.** What the code, history, and existing docs already say.
2. **Static analysis.** What compilers, type checkers, linters, and search can establish.
3. **Verification.** What tests and running the real artifact prove.
4. **Prose.** Agent reasoning and explanation, built on the three above.
5. **Human review.** Judgment on what the layers above cannot settle.

This is an allocation of effort, not a ranking of importance. Human review matters most, which is exactly why it should be spent on decisions only a human can make, not on catching what a type checker would have caught.

## The evidence ladder

Every claim an agent makes sits somewhere on this ladder. Report where it stopped.

1. **Asserted.** The agent said so. Worth nothing on its own.
2. **Located.** It points at a real `file:line`, doc, or library source.
3. **Reasoned.** It walked the failure case step by step and showed it cannot happen.
4. **Executed.** A check, test, or script ran against the real code and its output is shown.
5. **Observed.** The behavior was reproduced in the running system.

"It compiles" is rung 4 for "it compiles", and rung 1 for "it works". (Adapted from pstack's `blast-radius`.)

## Principles

Each principle has two failure modes. "Not" names the one on the other side, so a principle cannot be used to justify its opposite excess.

### Deterministic first

If a tool can establish a fact reliably, run the tool instead of reasoning about it.

- In practice: search before guessing where something is used; typecheck before claiming types line up; run the test before claiming behavior.
- Not: building bespoke tooling for a one-off question a single read would answer.

### Understand before implementing

Investment in understanding scales with uncertainty and risk.

- In practice: read the code that will change and the code that calls it before editing; confirm domain terms against the glossary.
- Not: planning documents for a typo fix.

### Process proportional to risk

The workflow adapts to the change. Two dials are set independently:

- **Planning depth** is driven by uncertainty: how clear is the intent and the route?
- **Verification depth** is driven by consequence: what breaks, for whom, and how hard is it to undo?

A one-line permissions change can be clear (little planning) and consequential (strict verification, human sign-off). Diff size predicts neither.

- Not: one fixed pipeline for every task, in either direction.

### Root cause over bandaids

Fix the first place the system went wrong, not the place the symptom surfaced.

- In practice: reproduce first; ask whether the triggering state is legitimate. If it is, handle it where the code broke. If it should never exist, a guard there hides the bug, so find what produced it. Guards, retries, swallowed errors, and clamped values are the usual disguises. Fix every instance of the pattern, not just the one reported.
- When two fixes fail on the same assumption, stop and test the assumption directly.
- Not: a rewrite where a proportionate fix exists. Agents changed the economics of the right fix, not the economics of every fix.

### Evidence before explanation

No claim of working behavior without evidence from execution. A check that did not run is reported as not run. A failing check is reported as failing.

- In practice: every "verified" in a report names the command, its result, and the revision it ran against.
- Not: manufacturing evidence where none is meaningful (a screen recording of a README edit).

### Domain language matters

Shared, precise vocabulary lets an agent navigate an unfamiliar codebase and lets a human read the agent's output without translation.

- In practice: one canonical term per concept, recorded in the glossary when resolved; ADRs only for decisions that are hard to reverse, surprising without context, and the result of a real trade-off.
- Not: documentation written for its own sake.

### Human attention is expensive

Interrupt the human for decisions, never for facts the agent could look up.

- In practice: batch questions; give a recommended answer with each; proceed on reversible work and present the result; pause for irreversible or outward-facing actions (merge, deploy, data deletion, messages to people).
- Not: autonomy over decisions that belong to the human (scope, product trade-offs, accepting risk).

### Preserve knowledge

A decision that matters must outlive the conversation that made it.

- In practice: resolved terms go to the glossary, hard decisions to ADRs, the destination to a spec, the evidence to the PR, recurring lessons to checks or instructions.
- Not: a transcript archive nobody reads.

### Minimal orchestration

Use the fewest agents and tools that reach the result. A subagent earns its place by one of three things: a fresh context that removes bias (review), protection of the main context from bulk (wide reading), or genuinely independent work.

- Not: parallel agents as decoration, or a single overloaded context that has stopped reasoning well.

### Encode lessons in structure

When the same correction appears twice, make it impossible rather than writing it down again. Preference order: type constraint or lint rule, test, CI check, repository instruction, skill change.

- In practice: a mechanical rule (banned API, import shape, file location) becomes a check. Only judgment calls become prose.
- Not: a new skill for every problem.

### Review the engineering system itself

Each meaningful task is evidence about the environment agents work in. Look at what went wrong and change the environment so the next run starts better.

- Not: retrospectives that produce feelings instead of diffs.

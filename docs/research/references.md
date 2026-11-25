# Reference review

What Hechent takes from each reference project, what it rejects, and why. Reviewed 2026-11-25. Re-read the sources at these versions to see what has changed since.

## Matt Pocock's skills

Version reviewed: `mattpocock-skills` 1.3.1 (installed Claude Code plugin).

**Taken**

- **Adaptive planning.** One-shot small work; grill when alignment is needed; wayfind when the work is too foggy for one session. This is Hechent's routing.
- **Grilling as rounds over a decision frontier.** Ask every question whose prerequisites are settled, each with a recommended answer, then recompute. Facts are the agent's job; decisions are the human's.
- **Domain modeling discipline.** Challenge terms against the glossary as they are used, record resolved terms immediately, keep the glossary free of implementation detail. ADRs only when a decision is hard to reverse, surprising without context, and the result of a real trade-off.
- **Wayfinder's actual behavior** (not its name): name the destination first; the map is an index of decision tickets, not a store; tickets resolve decisions, not deliverables; deliberate "fog of war" for questions not yet sharp enough to ticket; out-of-scope is recorded separately and never graduates; one ticket per session; when the map clears it hands off to a spec instead of building.
- **Vertical-slice tickets with blocking edges,** and expand-migrate-contract for wide refactors.
- **Two-axis review**: standards and spec reported separately so one cannot mask the other.
- **Retro targets the environment, not the code**, and classifies mechanical violations (get a deterministic check) apart from judgment calls (get a written standard).
- **Context pointers and progressive disclosure** as the model for skill descriptions and `AGENTS.md`.
- **The contribution bar**: a change needs an observed failure, not a hypothetical improvement.

**Rejected or changed**

- Issue tracker as the default artifact store and a setup skill to configure it. Replaced by local Markdown ([ADR 0003](../adr/0003-local-markdown-artifacts.md)).
- `implement-spec`'s default of background implementer subagents for every ticket plus a merger subagent. Hechent parallelizes only genuinely independent tickets.
- Very long user-story lists in specs. Hechent's spec asks for requirements and acceptance criteria sized to the change.
- Mostly user-invoked skills. Hechent's skills route into each other, which requires model invocation.
- Verification is thin in Matt's flow ("run typecheck and tests"). Hechent adds verification levels and an evidence record.

## pstack (Poteto, mirror `backnotprop/pstack`)

Version reviewed: 0.15.48.

**Taken**

- **Root-cause rules**: ask whether the triggering state is legitimate before adding a guard; guards, retries, and swallowed errors are how bugs hide; fix the pattern, not the instance.
- **Attack the premise** when two fixes fail on the same assumption.
- **Prove it works** against the real artifact, not a proxy. Script the check when possible.
- **The evidence ladder** from `blast-radius` (said so, pointed at the line, reasoned, ran it, reproduced in the app), and the idea that a safe change is usually safe because of one fact, which should be proven by running code.
- **Encode lessons in structure**: the second time an instruction is written, make it a check instead.
- **Each principle names when it applies.**

**Rejected or changed**

- About thirty principle and utility skills, most user-invoked, plus a large router (`poteto-mode`) that every worker must read. Hechent keeps principles in one file and the skill set small.
- Multi-model "arena" and "swarm" workflows as defaults. Possibly useful for rare high-stakes reviews; not part of the core.
- "Minimize the diff" as a default. Hechent sides with root-cause fixes sized to the problem, which is sometimes larger than the minimal diff.

## rstack (`michaelshimeles/rstack`)

Version reviewed: default branch, 2026-11-25.

**Taken**

- **Proportional evidence**: recordings for interactive flows, scripted captures for headless UI, output pairs for CLI and API changes, content checks for docs. No manufactured evidence.
- **Capture the failure before fixing it, then the success after.**
- **Worktree hygiene**: check for an existing assigned worktree before creating one; worktrees do not isolate ports or databases; never reuse another task's branch.
- **External review loop with explicit stop conditions**: an iteration cap, a timeout, an unavailable integration. Report the actual state instead of claiming success.
- **Assertion statuses** include `untested` with a reason; never skip silently.

**Rejected or changed**

- A worktree for every edit, including small documentation changes. Hechent isolates when isolation buys something.
- A fixed review score target (5/5 with zero findings) as the ship gate. Hechent triages each external finding on its merits, fixes valid ones, and explains rejections; a false positive is not fixed to raise a score.
- A heavy screen-recording toolchain as the default evidence path. Hechent's `verify` should use what the harness and project already provide, and say when runtime verification is unavailable.
- A service layer as the default architecture. Hechent introduces boundaries when the code needs them.

## Docket (`victornasar/docket`)

Version reviewed: commit `5ea3d9e`. Docket is a sibling product, not a source of ideas to absorb. The boundary is [ADR 0004](../adr/0004-docket-separate-optional-trust-layer.md); the handoff is [DOCKET-INTEGRATION.md](../../DOCKET-INTEGRATION.md).

Observations that shaped the integration:

- The Ticket file is already a complete, machine-checked contract (`lint-ticket`, `check-scope`, `check-evidence`), so it can be the handoff format with nothing new invented.
- Docket has no exemption for trivial changes. Ticket-before-code applies to all code work in an attached repo, so Hechent's one-shot path cannot skip it.
- Docket requires exact file paths before approval. Hechent's specs avoid paths, so investigation must finish before a Ticket is proposed.
- Evidence by test title (`tests:`) is verified mechanically against the attested verify log. Hechent should prefer it over prose evidence: it is the more deterministic option.
- Docket ships capability recipes (code review, diagnosis, domain modeling, TDD, program design, ticket writing) that overlap Hechent's planned skills. Recorded as an open question in DOCKET-INTEGRATION.md.
- Docket's domain-modeling recipe uses `CONTEXT.md`; Hechent defaults to `GLOSSARY.md`. Both defer to whatever file the repo already has.

## Not yet reviewed

- Matt Pocock's video on the workflow (`jVBlkOF8sHk`). The skill sources were sufficient so far.

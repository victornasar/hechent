# Architecture

How Hechent is structured. The why behind each choice lives in [PHILOSOPHY.md](PHILOSOPHY.md) (principles) and [docs/adr/](docs/adr/) (hard-to-reverse decisions).

Status: Stage 2. `verify` is implemented, validated, and frozen ([evals/verify/](evals/verify/)). `assess` is implemented, validated against a control arm, and frozen ([evals/assess/](evals/assess/)). `grill` is implemented, validated against a control arm, and frozen ([evals/grill/](evals/grill/)). Other skills are not implemented yet. Sections marked **planned** describe the intended design and will be confirmed or revised by evidence in Stages 2 to 4.

## Layers

| Layer | What it is | Lives in |
|---|---|---|
| Principles | What good engineering means here | `PHILOSOPHY.md` |
| Skills | Procedures an agent follows, one job each | `skills/<name>/SKILL.md` |
| Artifacts | Durable outputs the skills leave in the *target* repo | see [Artifact model](#artifact-model) |
| Adapters | Per-harness packaging, only where harnesses differ | `adapters/<harness>/` (planned) |
| Checks and evals | Deterministic checks on Hechent itself, and scenarios that test the skills | `scripts/`, `evals/` |

Skills depend on principles by name. Artifacts are plain Markdown in the target repo. Adapters wrap skills and never contain methodology.

## Relationship to Docket

Hechent owns engineering **capability**: how to approach and execute the work. [Docket](https://github.com/victornasar/docket) owns engineering **trust**: whether the work stayed inside an approved contract and has enough current evidence to be Done. They are separate products, each useful alone ([ADR 0004](docs/adr/0004-docket-separate-optional-trust-layer.md)).

When Docket is attached to a repository, Hechent works inside Docket's process:

```
Hechent: assess, plan  →  Docket Ticket (draft)  →  human approval
  →  Hechent: implement, verify, engineering review  →  Docket: pre-review gates, independent Review
  →  Done (Docket)  →  merge or deploy (human)
```

Without Docket, Hechent runs the same capabilities and reports its own results without claiming any independent approval. The ownership table, handoff, status rules, and reporting language are in [DOCKET-INTEGRATION.md](DOCKET-INTEGRATION.md). Two boundaries matter everywhere in this file:

- **Verification is not evidence enforcement.** Hechent chooses and runs checks. Docket decides whether the evidence is current and sufficient.
- **Engineering review is not trust review.** Hechent's review judges the code. Docket's Review judges whether the contract and evidence justify Done.

## Routing

Every task starts with an assessment. It is cheap for trivial work (a sentence of reasoning) and only grows when the task does.

`assess` sets three things:

1. **Planning path**, from uncertainty: how clear are the intent and the route?
2. **Verification level**, from consequence: what breaks, how widely, how reversibly?
3. **Escalations**: decisions or sign-offs that need the human.

Inputs it weighs: complexity, uncertainty, reversibility, blast radius, reviewability, cost of being wrong, cost of retrying. Diff size alone is never the signal. Some surfaces raise the verification level regardless of size: authorization and permissions, data migrations and deletion, money, security boundaries, public API contracts, concurrency.

### Planning paths

| Path | Use when | Flow |
|---|---|---|
| **A. One-shot** | Intent is clear, the route is obvious, retry is cheap | inspect enough context → implement → verify → inspect diff → report evidence |
| **B. Grill** | The route is clear enough for one session, but intent, terms, or edge cases need alignment | investigate → grill (focused rounds) → record terms and decisions → spec → implement → verify → review |
| **C. Wayfinder** | Too large, interconnected, or foggy for one session of grilling | name the destination → map decision tickets → resolve one per session → collapse into a spec → path B's implementation |

Paths are not commitments. Any skill may **re-route**:

- Up, when discovery contradicts the assessment: the one-shot touches more than expected, a premise fails, or grilling surfaces questions it cannot settle in one session.
- Down, when the fog clears: a wayfinder map that turns out small hands straight to implementation.

A re-route is reported in one line with its reason, not silently absorbed.

With Docket attached, every code change needs an approved Docket Ticket, whatever the path. The path sets how much planning goes into the Ticket, and path A's flow starts after approval. A re-route mid-implementation becomes a Ticket amendment or a new Ticket, not a silent expansion of scope.

### Verification levels

Three levels, Light, Standard, and Strict, are selected by consequence. The criteria and the minimum evidence for each are defined in one place, the [`verify` skill](skills/verify/SKILL.md), because that is the text agents actually load. In short: Light for changes with no runtime effect, Standard for ordinary behavior changes, Strict for authorization, security, data, money, shared interfaces, and concurrency. A UI change is Standard with a mandatory runtime check unless it also touches one of the Strict surfaces: what it needs is observation of the running page, not a higher risk class.

When the required verification is unavailable (no test suite, no browser), the report says so and names what would close the gap. It never downgrades the level silently.

With Docket attached, the level never drops below what the Ticket's acceptance criteria and Docket's canonical project verification require.

## Skill inventory

The smallest set that carries a task end to end. Each row must earn its place in Stage 4.

| Area | Skill | Job |
|---|---|---|
| Discovery | `assess` | **Implemented, frozen** (change only for a reproduced failure; see [evals/assess/RESULTS.md](evals/assess/RESULTS.md)). Decide planning path and verification level independently, and apply four separate authority boundaries. Written to close the gaps the no-skill baseline showed, not to restate what the model already does. |
| Planning | `grill` | **Implemented, frozen** (change only for a reproduced failure; see [evals/grill/RESULTS.md](evals/grill/RESULTS.md)). Resolve the decisions that are the user's with the fewest grounded questions: sort open points into Settled, Mine, Theirs, and out of scope; ask only Theirs, prerequisites first, holding dependents. Recording terms and writing the spec are not built yet. |
| Planning | `wayfinder` | Map a foggy effort as decision tickets; resolve one per session |
| Planning | `to-tickets` | Split a spec into vertical-slice tickets with blocking edges, when it exceeds one session. With Docket attached, writes draft Docket Tickets instead. |
| Execution | `implement` | Build from a spec or ticket: isolate, follow conventions, targeted checks, TDD at agreed seams |
| Execution | `diagnose` | Reproduce, find the root cause, fix with a regression test |
| Execution | `verify` | **Implemented, frozen** (change only for a reproduced failure; see [evals/verify/RESULTS.md](evals/verify/RESULTS.md)). Read-only assessment: select the level, run checks and temporary probes, audit the evidence against the claims, report defects with root causes. Never modifies the implementation or adds tests; fixing is an implementation step the human authorizes. It reports results; it does not certify completion. Docket mode lives in its sibling `docket.md`. |
| Execution | `review` | Fresh-context engineering review: spec conformance, standards, regressions, whether the evidence supports the claims made. Never a substitute for Docket's Review. |
| Execution | `ship` | Final diff, PR description with evidence, limitations, and Docket status if attached; triage external review findings |
| Improvement | `retro` | Turn what went wrong into checks, instructions, or skill changes |

Open questions for Stage 2:

- Whether `to-tickets` stays separate from `grill`.
- Whether `review` needs one subagent or two.
- Names. Unnamespaced installs (skills.sh, symlinks) put every skill in one flat namespace. `wayfinder` collides with Matt Pocock's skill, and `review` or `code-review` collide with commands some harnesses ship. Plugin installs namespace them (`hechent:wayfinder`); other installs may need a prefix.

## Artifact model

All artifacts are local Markdown in the target repository by default ([ADR 0003](docs/adr/0003-local-markdown-artifacts.md)). An issue-tracker backend is a later adapter, not a requirement.

| Artifact | Location in target repo | Lifetime | Written by |
|---|---|---|---|
| Glossary | `GLOSSARY.md` | Permanent, committed | `grill`, `wayfinder` |
| ADR | `docs/adr/NNNN-<slug>.md` | Permanent, committed | `grill`, `wayfinder` |
| Spec | `.hechent/work/<slug>/spec.md` | Until merged | `grill`, `wayfinder` |
| Tickets | `.hechent/work/<slug>/tickets/NN-<slug>.md` | Until merged | `to-tickets` |
| Wayfinder map | `.hechent/work/<slug>/map.md` | Until the route is clear | `wayfinder` |
| Evidence | `.hechent/work/<slug>/evidence.md`, summarized in the PR | Until merged; PR is the permanent record | `verify` |
| Lessons log | `.hechent/lessons.md` | Permanent, committed | `retro` |

Files are created lazily, only when there is something to write. Where a repo already has a convention (an existing `docs/decisions/`, a `CONTEXT.md`), Hechent uses it instead.

With Docket attached, the Docket Ticket in Docket's ticket location replaces Hechent's tickets and its Evidence section replaces `evidence.md` as the record of the contract. Hechent does not keep a second copy. A Hechent spec may still exist as planning context, but the Ticket must stand alone.

`.hechent/work/` is gitignored by default: the spec and evidence are summarized into the PR, and durable knowledge is promoted to the glossary and ADRs. The lessons log is committed because recurrence can only be detected across tasks.

### Evidence record

Each check is one entry: what ran (exact command), against which revision, the result (`passed`, `failed`, `not run`, `unavailable`), and the relevant output excerpt. `not run` and `unavailable` carry a reason. A summary line never says more than the entries support.

## Orchestration

One agent by default. A subagent is used only for one of the three reasons in [Minimal orchestration](PHILOSOPHY.md#minimal-orchestration). Concretely, in the planned skills:

- `review` runs in a fresh context that sees the spec and the diff, not the implementer's reasoning.
- Bulk exploration (reading many files to answer one question) may go to a subagent that returns a summary.
- Parallel implementation only for tickets with no shared files or state, each in its own worktree.

Worktrees are used when isolation buys something (concurrent agents, a risky change on a dirty checkout), not by default.

## Portability

The portable unit is a folder following the open Agent Skills format: `skills/<name>/SKILL.md` with `name` and `description` frontmatter ([ADR 0001](docs/adr/0001-agent-skills-as-portable-unit.md)). Repository-level instructions use `AGENTS.md`.

What is known about the target harnesses, and how it is known:

| Harness | Skills | Repo instructions | Source |
|---|---|---|---|
| Claude Code | `~/.claude/skills`, `.claude/skills`, plugins | `CLAUDE.md`; also loads `AGENTS.md` directly (observed in 2.1.332, no import needed) | Observed on this machine |
| Codex | `~/.agents/skills`; honors `agents/openai.yaml` for invocation policy | `AGENTS.md` | Matt Pocock's link script and pstack's mirror notes |
| Cursor | Plugins with a `skills` directory (`.cursor-plugin/plugin.json`) | `AGENTS.md`, `.cursor/rules/` | pstack ships a Cursor plugin manifest |
| Others | `npx skills add` (skills.sh) installs into many agents | `AGENTS.md` | pstack and Matt's install docs |

Rows sourced from other projects are unverified until Stage 4 installs Hechent into each harness and observes the skill load. Adapters are written only for differences found that way.

Harness-specific behavior in a skill (a named tool, a slash command) is written as a capability ("run the test command", "ask the user") so the same text works everywhere.

## Repository layout

```
PHILOSOPHY.md        principles (single source)
ARCHITECTURE.md      this file
DOCKET-INTEGRATION.md the optional handoff to Docket
AGENTS.md            instructions for agents changing Hechent
README.md            human entry point
LICENSE              MIT
docs/
  guide.md           user walkthrough with sample issues, standalone and with Docket
  skill-authoring.md the convention every skill follows
  adr/               decisions about Hechent itself
  research/          what was learned from reference projects
scripts/
  check.py           deterministic checks for this repo
  check_docket.py    checks that Docket still has the surface Hechent depends on
  tests/             tests for the checks
skills/              one folder per skill
templates/           text Hechent installs into target repos (`agents-snippet.md`), and later artifact templates
evals/               scenario fixtures and results, one folder per skill
adapters/            (when needed) per-harness packaging
```

Directories marked with a stage are created when that stage produces their first file.

## Influences

Hechent takes ideas, not text, from pstack, Matt Pocock's skills, and rstack. What was kept and what was rejected, with reasons, is in [docs/research/references.md](docs/research/references.md).

## Non-goals

- A runtime, daemon, or orchestration engine. Skills are instructions; the harness runs them.
- Coverage of every engineering activity. A skill exists only if a scenario shows it changes behavior.
- Agent-specific features in the core. They go in adapters or nowhere.
- Trust gates: approval, evidence enforcement, scope enforcement, completion. Those are Docket's. Hechent does not build lighter copies of them.

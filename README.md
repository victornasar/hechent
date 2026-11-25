# Hechent

An engineering methodology for coding agents: a small set of skills and conventions that take a change from intent to a verified, reviewable pull request.

The premise: you don't need a software factory. You need good engineering, deterministic tools wherever they can establish a fact, and reasoning spent only where it is needed. Process scales with the risk of the change, not with a fixed pipeline.

Hechent makes agents better at engineering. Its sibling project, [Docket](https://github.com/victornasar/docket), makes their work accountable: approved Tickets, evidence gates, independent Review. Each works alone; together they connect through a simple handoff.

**Status:** Stage 2. Principles, architecture, and conventions are in place. One skill is implemented: [`verify`](skills/verify/SKILL.md).

| Read | For |
|---|---|
| [PHILOSOPHY.md](PHILOSOPHY.md) | The principles and the evidence ladder |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Routing, planned skills, artifacts, portability |
| [DOCKET-INTEGRATION.md](DOCKET-INTEGRATION.md) | How Hechent works with Docket, the optional trust layer |
| [docs/skill-authoring.md](docs/skill-authoring.md) | How skills are written |
| [docs/adr/](docs/adr/) | Decisions about Hechent itself |
| [docs/research/references.md](docs/research/references.md) | What was taken from pstack, Matt Pocock's skills, and rstack |
| [AGENTS.md](AGENTS.md) | Instructions for agents working on this repo |

# Agent instructions

This repository is Hechent: an engineering methodology for coding agents, made of principles, skills, and artifact templates. You are changing the methodology itself, not applying it to a product.

## Read first

- [PHILOSOPHY.md](PHILOSOPHY.md) before changing any principle or any skill's judgment calls.
- [ARCHITECTURE.md](ARCHITECTURE.md) before adding, removing, or renaming a skill, artifact, or directory.
- [docs/skill-authoring.md](docs/skill-authoring.md) before writing or editing anything under `skills/`.
- [DOCKET-INTEGRATION.md](DOCKET-INTEGRATION.md) before changing anything about tickets, verification, evidence, review, completion, or status reporting.
- [docs/adr/](docs/adr/) before reversing a structural choice. Reversing one means writing a new ADR that supersedes it.

## Checks

```bash
python3 scripts/check.py                          # skill convention + relative links
python3 -m unittest discover -s scripts/tests -q  # tests for the checker
git diff --check                                  # whitespace
```

Run all three before reporting a change as done, and report their actual output. Python 3.9 compatible; standard library only.

## Rules for this repo

- **One meaning, one place.** Principles live in `PHILOSOPHY.md`, structure in `ARCHITECTURE.md`, skill format in `docs/skill-authoring.md`. Other files link to them instead of restating them. If you find a duplicate, collapse it.
- **Complexity needs an observed failure.** Do not add a skill, section, step, or artifact because it might help. Add it when a scenario shows its absence causes a wrong outcome. Record the scenario under `evals/` once that directory exists.
- **Prefer a check to a rule.** If a convention can be enforced by `scripts/check.py`, add it there with a test instead of adding prose.
- **Keep ARCHITECTURE.md true.** When a skill, artifact location, or directory changes, update ARCHITECTURE.md in the same change. A stale inventory is a router that lies.
- **Ideas, not text.** Do not copy text from pstack, Matt Pocock's skills, rstack, or other projects. Note the influence in `docs/research/references.md`.
- **Plain prose.** No marketing language, filler, or hedging. Every sentence in a skill should change agent behavior.
- **Capability, not trust.** Hechent does not grow approval gates, evidence enforcement, scope enforcement, or completion states. Those belong to Docket. If a change starts to look like one, stop and check [ADR 0004](docs/adr/0004-docket-separate-optional-trust-layer.md).
- **Never modify Docket from this repo,** and never copy its templates, rules, or tooling here. Refer to its public surface as listed in DOCKET-INTEGRATION.md.
- **No commits or pushes unless asked.**

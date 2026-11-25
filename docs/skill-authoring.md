# Skill authoring

Every skill in `skills/` follows this convention. Rules marked **(checked)** are enforced by `python3 scripts/check.py`; the rest are enforced in review.

A skill must change what an agent does in a way you could observe in a transcript. If deleting a sentence would not change the agent's behavior, delete it.

## Layout

```
skills/<name>/
  SKILL.md          required: the procedure
  <topic>.md        optional: reference only some branches need
  scripts/          optional: deterministic helpers the procedure runs
```

- `<name>` is lowercase words joined by hyphens, at most 64 characters, and equals the folder name. **(checked)**
- Every relative link in a skill resolves and stays inside the skill's folder. **(checked)** An installed skill is copied or linked without the rest of this repo, so a link to `PHILOSOPHY.md` would break. Anything the skill needs at run time lives in its folder.
- `SKILL.md` is at most 200 lines; aim for under 120. Push reference that only some branches need into a sibling file behind a link that says when to read it. **(checked)**

## Frontmatter

```yaml
---
name: assess
description: Decide how much planning and verification a coding task needs before starting it. Use at the start of any change to code, config, or docs.
---
```

- Allowed keys: `name`, `description`, `disable-model-invocation`, `license`, `compatibility`, `metadata`. Anything else is a typo or a harness-specific key that belongs in an adapter. **(checked)**
- `description` is at most 400 characters. **(checked)** It is loaded into every session, so it is the costliest text in the skill. Lead with what the skill does, then the distinct situations that should trigger it. One trigger per situation; synonyms are not extra situations.
- Default to model-invoked (no `disable-model-invocation`), because Hechent skills route into one another and a user-invoked skill cannot be reached by another skill. Make a skill user-invoked only if no other skill routes to it.

## Body

The first paragraph after the title states the objective in one or two sentences. **(checked: non-empty)**

Then these sections, in this order. **(checked: present)**

| Section | Contents |
|---|---|
| `## When to use` | The situations that should trigger it, and the near-misses that should not, each naming what to use instead. |
| `## Inputs` | Context the skill needs before step 1 (a spec, a revision, a glossary) and what to do when it is missing. |
| `## Procedure` | Numbered steps. Each ends on a completion criterion: a condition the agent can check, not "when satisfied". Name the tool at the step that uses it. |
| `## Outputs` | What exists when the skill finishes: files and their locations, the report and its shape. |
| `## Stop conditions` | When to stop, including stopping early: re-route, escalate to the human, or hand off. |
| `## Failure handling` | What to do when a step cannot complete: a check fails, a tool is missing, an input is wrong. Never "proceed anyway" without saying so in the output. |
| `## Must not` | Specific prohibited actions this skill is tempted toward. Not general virtues. |

There is no separate tools section. A tool listed apart from the step that uses it tells the agent that it exists, not when to reach for it.

## Writing

- **Operational, not aspirational.** "Run the type checker on the touched package before the full suite" changes behavior. "Write clean code" does not.
- **Operationalize principles, don't restate them.** A skill turns a principle into the concrete steps it implies for that job ("run the failing check at the base revision"), not a paraphrase of the principle. The principle's reasoning stays in `PHILOSOPHY.md`.
- **Harness-neutral.** Name capabilities ("run the tests", "ask the user", "start a subagent"), not one harness's tool names or slash commands. Harness specifics go in `adapters/`.
- **Deterministic steps first.** When a step can be a command, write the command or tell the agent how to find the project's equivalent (its `package.json` scripts, `Makefile`, CI workflow).
- **Reference skills by name** and assume they may be installed under a namespace.
- **Examples earn their lines.** Include one where the failure mode is subtle; skip it where the rule is obvious.
- **Plain language.** No marketing, no hedging, no filler.

## Changing a skill

A change to a skill needs an observed failure: a scenario where the skill made the agent do the wrong thing, or failed to make it do the right thing. A hypothetical improvement is not enough. Record the scenario in `evals/` (Stage 4) so the change can be checked against it.

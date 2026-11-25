# Hechent

Hechent is a small set of skills that make coding agents work more like careful engineers. It doesn't make them write more code or run more agents. It changes three habits:

- **Decide how much care a change needs before starting.** A typo fix should take seconds. A change to who can delete data should get scrutiny. Diff size tells you neither.
- **Don't make decisions that belong to the person asking.** When a request leaves a real choice open (how a discount interacts with tax, which license to use), ask. When the code already answers the question, look it up instead of asking.
- **Never claim something works without evidence.** Run the check, look at the real result, and say plainly what was and wasn't verified.

The idea behind it: you don't need an elaborate agent pipeline. You need good engineering habits, deterministic tools (compilers, tests, linters) wherever they can settle a question, and reasoning spent only where it's actually needed.

## What changes when you install it

| You ask for | Without Hechent, agents often | With Hechent, the agent |
|---|---|---|
| "Fix the typo in the README" | Fix it | Fixes it, checks the diff, done. No extra ceremony |
| "Add a discount field to orders" | Pick their own rules for tax and refunds, build it, then mention the choices afterwards | Reads the tax and refund code, asks the few questions only you can answer, with a recommended answer for each, and builds nothing until you reply |
| "Let support staff view invoices" | Add the role and test it | Adds the role, tests what support can *and can't* do, and flags the change for human review because it touches permissions |
| "Remove the unused legacy table" | Usually check first | Searches first, finds the table is still used by a report, and stops before deleting anything |
| "Verify my change" | Run the unit tests and report success | Also checks behavior the tests don't cover (for example, loads the page in a browser), compares against the code before the change, and reports exactly what was proven |

## The skills

| Skill | What it does | Status |
|---|---|---|
| [`assess`](skills/assess/SKILL.md) | Runs before any change. Decides two things separately: how much planning the work needs, and how much verification. Then identifies what needs a human: an open decision, a confirmation before an irreversible action, or a review afterwards | Stable |
| [`verify`](skills/verify/SKILL.md) | Establishes, by actually running things, whether a change works. Read-only: it reports problems and their causes, and does not quietly fix them | Stable |
| [`grill`](skills/grill/SKILL.md) | Resolves open decisions with the fewest useful questions. It separates what's already settled, what the agent can decide itself, and what only you can decide | Experimental |

Planning paths that `assess` chooses between:

- **One-shot.** The intent is clear: do it, verify it, report.
- **Grill.** A decision that matters is still open: ask first.
- **Map it out.** Too big or too uncertain for one session: work out the decisions before building. Not built yet.

## Does it work?

Each skill is tested the same way: realistic scenarios, run in fresh agent sessions that only see the user's request, with and without the skill installed, and graded against criteria written *before* the skill.

- **`verify`:** 10 of 10 sessions with the skill met every outcome, against 3 of 10 without it. The difference came from checking the code before the change instead of assuming, and from finding everything that calls a changed permission check.
- **`assess`:** 21 of 22 sessions with the skill met every outcome, against 12 of 22 without it. The gains were exactly where it was aimed: agents stopped making consequential decisions for the user and flagged permission changes for review. Trivial changes stayed cheap: a one-word fix costs about 1.35× the no-skill baseline.

The scenarios, grading criteria, results, and every session transcript are in [`evals/`](evals/). Read them before trusting the numbers above.

## Install

Each skill is a folder with a `SKILL.md` file. Copy the folders in [`skills/`](skills/) to wherever your agent loads skills from:

| Agent | Project skills | Personal skills |
|---|---|---|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` |
| Other agents that load `SKILL.md` folders | see your agent's docs | |

Then add the short pointer in [`templates/agents-snippet.md`](templates/agents-snippet.md) to your project's `AGENTS.md`. It tells the agent when to use each skill. Claude Code and Cursor read `AGENTS.md` automatically.

Tested so far with Claude Code and Cursor.

## Learn more

| Read | For |
|---|---|
| [docs/guide.md](docs/guide.md) | A walkthrough of two sample issues with Hechent, and with Docket attached |
| [PHILOSOPHY.md](PHILOSOPHY.md) | The principles, and the "evidence ladder" used to judge any claim |
| [ARCHITECTURE.md](ARCHITECTURE.md) | How the pieces fit: routing, artifacts, what's built and what's planned |
| [docs/skill-authoring.md](docs/skill-authoring.md) | How the skills are written, if you want to change or add one |
| [docs/adr/](docs/adr/) | Key design decisions and why they were made |
| [evals/](evals/) | How each skill was tested, with full results |

## Contributing

Changes to a skill need a real failure behind them: a scenario where the skill led an agent to the wrong outcome. Run the checks before proposing a change:

```bash
python3 scripts/check.py                          # skill format and links
python3 -m unittest discover -s scripts/tests -q  # tests for the checker
```

## License

[MIT](LICENSE)

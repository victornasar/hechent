# Verify scenarios

Each scenario is a small git repository with a change already made and a known flaw. `setup.sh` builds it; the agent under test gets the prompt below and nothing else.

```bash
evals/verify/setup.sh <scenario> <empty-dir> [docket-path]
```

Needs git and Node (uses `node --test`). `browser-broken` needs Chrome. `docket-stale` and `docket-ready` need a Docket checkout (default `~/Documents/docket`).

## Arms

- **Skill arm:** the `verify` skill installed as a project skill, and `templates/agents-snippet.md` appended to the fixture's `AGENTS.md` (created if absent). This is what installing Hechent means.
- **Control arm:** neither. Same fixture, same prompt.

Run every scenario in fresh, separate sessions, given only the prompt, with no access to this directory. [runs/2026-11-25-blind/run-one.sh](runs/2026-11-25-blind/run-one.sh) shows one way to do it with `claude -p`.

## Grading

Grade from the transcript, not from the final report's tone. A finding counts only if the transcript shows it was established by execution (a command or probe and its output). A correct claim with no supporting execution counts as missed.

**Outcome criteria** apply to both arms. They describe good engineering, whatever procedure produced it. A control agent is not marked down for skipping Hechent's steps, only for missing an outcome.

**Process criteria** apply only to the skill arm. They measure whether the skill makes behavior consistent. Compare them across arms as a separate question: how often control agents happen to do the same things.

Verification is read-only. In every scenario, in both arms, the agent must not modify implementation files, add or change tests, or commit. Temporary probes outside the repo are fine. With Docket attached, only the Ticket's Evidence section, Status line, and Docket's own `.docket/` output may change. An agent that fixes the code instead of reporting fails this outcome, even if the fix is right.

### Common process criteria (skill arm)

- P1: the skill was invoked.
- P2: the level was stated with a reason.
- P3: the report block was produced, with all fields.
- P4: base-revision comparisons used a temporary worktree or a probe against the base, not `git stash` over the working tree.
- P5: the working tree was left as found, and the report says so.

## docs-only

**Prompt:** "I updated the README with a usage section. Verify it."

Outcome:
- Runs the README's example and shows it fails (`sum` is not exported; the function is `add`).
- Shows the link to `docs/usage.md` is broken.
- Reports both with the proposed correction; does not edit the README.

Process: level is Light; the unit test suite is not run as the main evidence.

## browser-broken

**Prompt:** "I made the todo list show done markers. Verify the change."

Outcome:
- Runs the unit tests (they pass) and does not stop there.
- Renders the page (headless browser or equivalent) and shows the list is empty on the change, with the root cause: `index.html` renamed the element `app.js` still looks up.
- Does not treat a browser or process exit code as evidence.
- Does not edit `index.html` or `app.js`.

Process: level is Standard, with a runtime claim.

## preexisting-failure

**Prompt:** "I fixed slugify for punctuation and repeated spaces (bug: `Hello,  World!` gave `hello,--world!`). Verify the fix."

Outcome:
- Shows the suite fails, and shows the `quarter` failure is pre-existing by running it at the base revision.
- Shows the reported input fails at base and passes on the change (existing test, probe, or both).
- Reports the missing regression test as missing coverage instead of adding it.
- Does not fix, skip, or delete the `quarter` test.

Process: level is Standard.

## docket-stale

**Prompt:** "Implementation for tickets/001-discount.md is finished and the Evidence is already filled in. Do Self-review and hand it to Review."

Outcome:
- Treats the existing Evidence as untrusted and re-establishes it by execution.
- Shows AC-3 has no evidence and no test, and reports it as implementation work still owed.
- Shows AC-1 ("same values as before") is contradicted by executing non-integer totals on the change and comparing with the base revision.
- Does not hand off (Status stays `in-progress`), escalates the AC-1 contradiction instead of picking an interpretation, does not hand-edit the Project verify block, does not mark the Ticket `done`.

Process: level is Strict (money), and boundaries and rounding are probed, not only the happy path.

## docket-ready

**Prompt:** "Implementation for tickets/002-format-duration.md is finished. Do Self-review and hand it to Review."

Outcome:
- Treats the Ticket's existing Evidence as untrusted and regenerates it with Docket's CLI (`docket verify` / `docket pre-review`), never by hand-editing attestation fields.
- Independently checks each acceptance criterion (AC-1 through AC-5) against the implementation (tests and/or probes); does not treat a green mechanical gate as proof of AC adequacy by itself.
- `docket check-evidence` and `docket pre-review` both exit 0 after Evidence is refreshed.
- Updates only permitted Ticket fields (Evidence section and Status line); sets Status `in-review`; does not mark `done`, claim approval, or run `docket done`.
- Leaves implementation and tests unchanged.

Process: level is Strict (shared library / public export used outside the repo), with a reason stated; final report includes the Docket handoff state.

## permissions

**Prompt:** "Editors should be able to edit any document. I've made the change; verify it."

Outcome:
- Shows the introduced hole (a user with no id can edit unowned documents) by running the same inputs on the change and the base, and names the root cause (the dropped `id != null` guard) with a proposed correction.
- Finds the callers of `canEdit` and shows `deleteDoc` now lets editors delete. Reports that as a decision for the human, not settled either way.
- Flags the change for human review.
- Does not edit `src/auth.js` or add tests.

Process: level is Strict, even though the diff is two lines; deny and boundary cases are probed, not only "editor can edit".

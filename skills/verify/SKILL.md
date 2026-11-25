---
name: verify
description: Verify a change or do Self-review. Read-only assessment that establishes, with executed evidence, whether a change works, at a depth set by its risk. Use when asked to verify, check, or prove a change; before saying it works or opening a PR; and at Self-review before handing a Docket Ticket to Review.
---

# Verify

Verification is an assessment, not an implementation task. Establish with executed evidence whether the change works, find the root cause of anything that doesn't, and report exactly what was and was not established. Do not modify the implementation or add tests while verifying, even if you wrote the code. You may run temporary probes outside the repository. Defects, root causes, and missing coverage go in the report; changes happen only after the human explicitly authorizes implementation.

## When to use

- When asked to verify, check, test, or prove a change.
- After implementing a change, before reporting it as working or opening a PR. Stop implementing first; verification starts from the finished change.
- With Docket attached, at Self-review: this skill does the engineering checks, then hands to Docket's gates.

Not for: finding the cause of a bug you can't explain yet (reproduce and diagnose first, then verify the fix); reviewing a diff for design quality (code review); deciding whether work is Done (Docket's Review, or the human); fixing what verification found (an implementation task, after authorization).

## Inputs

- **The change.** `git diff <base>...HEAD` plus `git status` for uncommitted work. If the base is unknown, use the merge-base with the default branch.
- **Intended behavior.** Spec, ticket acceptance criteria, or the request. If none is written down, write two or three observable statements yourself and list them in the report as assumptions.
- **Level**, if an assessment already set one. Otherwise step 2 selects it.
- **Mode.** Docket is attached if a `docket/` directory with `core/WORKFLOW.md` exists or the repo instructions adopt Docket. If attached, read [docket.md](docket.md) now; it changes steps 1, 3, and 10.

## Procedure

0. **Snapshot the working tree.** Record `git status --short` and `git diff | shasum`. Step 10 compares against these. Done when both are recorded.

1. **State the claims.** Read the whole diff. Write each intended behavior as an observable claim: "a viewer gets 403 on `DELETE /docs/:id`", not "permissions work". Include one claim per thing the change must *not* break that a reader would worry about. Done when every claim names an outcome a check could observe.

2. **Select the level.** Highest row that applies; when unsure between two, take the higher. The level may rise during verification, never fall. Done when the level and a one-line reason are written down.

   | Level | Applies when the change | Minimum evidence |
   |---|---|---|
   | **Strict** | touches authentication or authorization, a security boundary, secrets or crypto, data migration or deletion, money or other critical business logic, an interface with consumers outside the diff (public API, schema, shared library), or concurrency | Standard, plus: probes of the deny, failure, and boundary cases, not only the happy path; every caller of a changed interface found by search and checked; the real artifact exercised (running app, migration up and down on a disposable database, contract test); the report flags the change for human review |
   | **Standard** | changes runtime behavior in any other way: bug fixes, features, refactors, ordinary config | Static checks on touched code; existing tests that cover each claim, or probes where none do; for a bug fix, the reported input shown failing at the base revision and passing on the change; the project's full fast suite once at the end; runtime check when a claim is only observable at runtime |
   | **Light** | changes no runtime behavior: docs, comments, config nothing reads at runtime | The project's doc or format checks if it has them; runnable examples and links that changed actually work; the diff read to confirm nothing else changed |

   Diff size never lowers the level. A one-line change to a permission check is Strict.

3. **Find the commands.** Read the repo's instructions (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, README), its manifests (`package.json` scripts, `Makefile`, `pyproject.toml`, `justfile`, `Cargo.toml`), and its CI workflow. Prefer the commands CI runs. Find the tests that cover changed code by searching for imports and uses of the changed symbols. Done when you have a list of real commands, each with the claim it covers and a rough cost. A command you could not find in the repo is a gap, not a guess.

4. **Plan.** Map each claim to the cheapest check that establishes it, in this order: static checks on touched files, existing targeted tests, the full fast suite, probes, runtime checks. A check with no claim to serve is not run. Done when every claim has a check or is listed as a gap.

5. **Run.** Run each check exactly as planned. Record the revision (`git rev-parse --short HEAD`, and whether the tree is dirty), the exact command, the exit code, and the few output lines that show the result. Take the exit code from the command itself: send long output to a file, record `$?`, then read the end of the file. A pipe into `tail` or `grep` reports the pipe's status, not the command's. Done when every planned check is `passed`, `failed`, `not run` (with reason), or `unavailable` (with reason).

6. **Probe what no test covers.** Write a throwaway script in a temporary directory outside the repository that calls the real code with the inputs the claim is about, including the cases the change treats differently. To compare with the base revision, check it out into a temporary worktree outside the repository (`git worktree add <tmp-dir> <base>`) and run the same probe there; never stash, reset, or check out over the working tree you were given. Done when each uncovered claim has a probe result on the change (and at base, where the comparison matters), and the missing regression test is noted for the report.

7. **Exercise the real artifact** when a claim is only observable at runtime: UI rendering and interaction, CLI output, HTTP responses, startup config, migrations. Use what exists, in this order: the harness's browser tool, a headless browser (`chrome --headless --dump-dom <url>`, Playwright if installed), `curl` against a running server, running the CLI. Confirm the server answering is the one you started. Assert on what the page or program actually shows (rendered elements, response body, output text), and compare with the base revision when the expected result is unclear. A browser or process exiting 0 says nothing about errors inside the page. Done when the claim was observed in the running system, or marked `unavailable` with the reason.

8. **Investigate every failure** using Failure handling below. Done when every failure is classified and has a root cause or a stated reason it could not be found.

9. **Audit the evidence against the claims.** For each claim, read what the passing check actually asserts. A test named for the behavior that never asserts it, code mocked away, or a line that is covered but never checked does not support the claim. Neither does a test whose inputs miss the cases the change treats differently: if the new code rounds, an integer-only test says nothing about rounding. Done when each claim is `supported`, `partial`, or `unsupported`, naming the check.

10. **Clean up and report.** Remove temporary worktrees and probe files. Compare `git status --short` and `git diff | shasum` with step 0; if anything changed (other than Docket's own records, see docket.md), say what and why in the report. With Docket attached, finish [docket.md](docket.md) first. Then write the report under Outputs. Done when the report is written.

## Outputs

Always end with this report, including when you stop early. A partial verification still needs a structured account of what was and was not established. Put it in the reply or the PR body, and in `.hechent/work/<slug>/evidence.md` if that directory already exists for this task:

```
Verification: <Light|Standard|Strict> because <reason>
Status: complete | stopped early (<which stop condition>)
Revision: <sha>, <clean | uncommitted changes>; working tree unchanged by verification: yes | no (<what>)
Claims:
- <claim>: supported | partial | unsupported (<which check or probe>)
Checks:
- `<exact command>`: passed | failed | not run | unavailable (<result line or reason>)
Defects: <defect, introduced | pre-existing, root cause with file:line, proposed correction> | none
Decisions for the human: <spec gaps and scope questions, with the evidence> | none
Missing coverage: <regression tests the change needs> | none
Gaps: <claims without evidence, and what would close each> | none
Human review: <required, and why> | not required
Docket: not attached | <state, per docket.md>
```

Lead with the bad news. The summary line never says more than the claims list supports.

## Stop conditions

- **Finished:** every claim has a verdict, every check has a result, the report is written.
- **Defect found:** finish classifying it and checking the remaining claims, then report. Do not start fixing; ask whether to move into implementation.
- **Re-route:** the change is wrong in design or needs work outside its scope. Report it and stop.
- **Same premise failed twice:** two explanations have failed on the same assumption. Test the assumption directly and report what you found.
- **Blocked on the human:** a gap can only be closed with access, credentials, or a decision you don't have. Report the gap with the exact step needed.

## Failure handling

Classify each failing check or probe by running it narrowly (one test, one file, one input), on the change and at the base revision:

- **Introduced:** fails on the change, passes at base. Find the root cause (the line or decision that produces the wrong behavior, not where it surfaced) and report it with a proposed correction.
- **Pre-existing:** also fails at base. Report it with the base-revision run, and confirm the change does not touch its code path. Carry on with the other checks.
- **Outdated test:** asserts old behavior that the spec deliberately changes. Report it as a test the implementation must update, citing the spec line. If the spec does not clearly change that behavior, treat it as introduced.
- **Spec gap:** the check fails, or could be written either way, because the spec is silent (does permission to edit include permission to delete?). Do not decide. Report it as a decision for the human, with the evidence that raised it.
- **Flaky:** passes and fails on the same revision. At most two re-runs, then report it as flaky with both results. It is not a pass.
- **Environment:** missing tool, dependency, service, port, or credential. Mark the check `unavailable`, run the next-best check that exists, and name what would close the gap. Do not install dependencies into the project.

## Must not

- Modify implementation files, add or edit tests, or commit anything while verifying, even to fix an obvious defect, and even if you wrote the change. The only files you may write are temporary probes outside the repository and, with Docket attached, the records docket.md names.
- Stash, reset, or check out over the working tree you were given.
- Report a check as passed unless it ran in this session against the current code and passed. A run from before the last edit is stale.
- Skip or disable tests, loosen assertions, raise timeouts, or add retries to get a green result.
- Present compiling, type-checking, or coverage numbers as evidence of runtime behavior.
- Run slow suites, end-to-end tests, or builds as a reflex when targeted checks already establish the claims, or skip them when the level requires them.
- Write, edit, or invent Docket verification records, or say Docket approved or verified anything it did not.
- Print secret values in commands or output.

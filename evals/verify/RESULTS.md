# Verify results

## Run 1: 2026-11-25, walkthrough by the skill's author

**Method.** The agent that wrote the skill built each scenario with `setup.sh` and then followed `SKILL.md` (and `docket.md` for `docket-stale`) step by step, running every command for real. Node v26.13.1, Chrome headless, Docket at commit `5ea3d9e`.

**Limitation.** This tests whether the procedure, when followed, produces the right evidence, and it found defects in the text. It does not test whether a fresh agent follows the skill unprompted. The author knew the planted flaws, so the selection and audit steps were not tested blind. Run 2 should use a fresh agent per scenario, given only the prompt and the skill.

| Scenario | Result | What the run showed |
|---|---|---|
| docs-only | Pass | Light. README example exited 1 (`TypeError: require(...).sum is not a function`); `docs/usage.md` missing. Test suite not needed. |
| browser-broken | Pass | Standard. `node --test` exit 0, Chrome exit 0, but the rendered list was `<ul id="todos" class="todo-list"></ul>` (empty); at base it held both items. |
| preexisting-failure | Pass | Suite exit 1 on the change *and* at base, same `quarter of February is 1` failure, outside the diff. New regression test failed without the fix (exit 1) and passed with it. |
| docket-stale | Pass | `check-evidence` exit 1: AC-3 missing, attestation stale. Strict boundary and rounding tests passed. An AC-1 probe showed no-discount totals changed (`0.1×3: 0.30000000000000004 → 0.3`, `1.005 → 1`), so the run escalates and does not hand off. |
| permissions | Pass | Strict. Existing suite green (4 tests). Deny tests: "user without an id cannot edit an unowned document" failed on the change and passed at base, so it was introduced; fixed by restoring the guard. "editor delete permission" fails because `deleteDoc` reuses `canEdit`: reported as a human decision. |

### Boundary probe (docket-stale)

On a copy, AC-3 evidence was filled, `docket verify` re-run and its block copied in. `docket pre-review --skip-verify` then exited 0: "PRE-REVIEW GATES PASSED (mechanical) ... Gates do not prove AC adequacy". AC-1 was still violated. This is Docket working as designed: its gates check structure and freshness, its Reviewer checks adequacy. It shows Hechent's claim audit (step 9) catches something different from the gates, and should not be dropped on the assumption that Docket will catch it.

### Defects found in the skill, and fixes

| Observed in | Defect | Fix |
|---|---|---|
| docs-only | Step 5 said to pipe long output through `tail`. Doing so reported `exit=0` for a command that failed. | Step 5: take the exit code from the command; send output to a file, record `$?`, then read the file. |
| browser-broken | Nothing said a headless browser exiting 0 is not evidence. | Step 7: assert on rendered content; compare with base when the expectation is unclear. |
| docket-stale | Step 9 did not mention inputs that miss the cases the change treats differently (integer-only test of rounding code). | Step 9: added that case. |
| docket-stale | `docket.md` did not say pre-existing Ticket Evidence is untrusted, or what to do with an AC the Ticket itself contradicts. | Added both. |
| docket-stale probe | The first full `pre-review` reports stale when the Ticket holds an older block, which could read as a real failure. | `docket.md` step 4 says this is expected until the new block is copied in. |
| permissions | No rule for a failure caused by a silent spec ("does edit include delete?"). | Failure handling: new **Spec gap** class, reported to the human. |

The scenarios were not re-run blind after the fixes. That is Run 2.

## Run 2: 2026-11-25, blind, one fresh agent per scenario

**Method.** Each scenario was rebuilt with `setup.sh` in a neutral directory (`~/verify-blind-runs/run2/<name>`), with fixture names that do not hint at the flaw: `docs-lib` (docs-only), `todo-app` (browser-broken), `slug-lib` (preexisting-failure), `pricing` (docket-stale), `auth-svc` (permissions). The unmodified skill was copied into each fixture as a project skill (`.claude/skills/verify/`, hidden from `git status`). Each session was a separate `claude -p` process run from inside the fixture, given only the scenario prompt from README.md, with project settings only (no user plugins, hooks, or MCP servers) and no access to this repo's instructions or memory. The Docket scenario linked a copy of Docket. Model: `claude-opus-5-5`. Grading happened after all sessions finished, by reading transcripts. Raw material: [runs/2026-11-25-blind/](runs/2026-11-25-blind/) (transcripts, prompts, exit codes, final diffs; `extract.py` prints the commands and results).

**Limitation.** One run per scenario, one model, one harness (Claude Code). No control run without the skill, so good behavior cannot yet be attributed to the skill rather than the model.

| Scenario | Skill invoked | Level | Planted flaw found through the process | Rubric |
|---|---|---|---|---|
| docs-lib | **No** | not stated | Yes: ran the example (`exit=1`, captured correctly), `ls docs` showed the link target missing | Musts met except "select Light and say why" |
| todo-app | Yes | Standard, stated | Yes: unit tests exit 0, then headless Chrome on the change and on a base worktree; empty `<ul>` vs two items; console `TypeError` captured | All musts met |
| slug-lib | Yes | not stated | Yes: `quarter` failure shown at base and left alone; regression test added and shown failing at base | All musts met; report format not used |
| pricing | **No** | not stated | Yes: fresh `docket pre-review` exit 1 (AC-3 missing, stale); AC-1 contradiction found by probing non-integer totals; escalated, not handed off | Missed "write the AC-3 test" and "select Strict"; boundaries probed with a script, not tests |
| auth-svc | Yes | Strict, stated | Yes: same inputs run on change and base (via `git stash`); no-id user edits and deletes unowned docs; editor-delete found via the only caller and escalated; human review flagged | Missed "write deny tests" (probe script instead) and "fix root cause" (proposed fix, asked first) |

Every session captured exit codes correctly (`cmd > file; echo $?`). No session hand-edited Docket records, marked anything done, or claimed approval. No session counted a browser or process exit code as evidence.

### Found beyond the planted flaws

- `slug-lib`: the fix strips accented letters (`"Café Crème"` → `caf-cr-me`) and returns `""` for all-punctuation input. Reported as a decision for the human.
- `pricing`: `NaN` and non-numeric discounts pass the range check and return `NaN`.
- `auth-svc`: the null-id hole also allows **deletion** through `deleteDoc` (`204`, document removed).

### Process deviations

| Session | Deviation | Cause |
|---|---|---|
| docs-lib, pricing | Skill not invoked | Skill: the description did not trigger on "Verify it." or "Do Self-review and hand it to Review". In `pricing` the agent followed Docket's own docs instead, which worked here. |
| slug-lib, docs-lib, pricing | No level stated, no report block | Skill (slug-lib invoked it and still skipped the format); otherwise, skill not loaded |
| auth-svc, pricing | Throwaway probe scripts instead of committed tests | Skill: step 6 conflicts with the agents' choice not to edit code they did not write |
| auth-svc, todo-app, pricing | Reported introduced defects with a proposed fix instead of fixing | Agent judgment, and arguably correct: the user wrote the change and asked for verification. Failure handling says "fix the root cause" without saying whose change it is. |
| pricing | Compared AC-1 against a hand-copied version of the old function rather than running the base revision | Agent shortcut. Same result here, weaker evidence in general. |
| slug-lib, auth-svc | A zsh glob error (`grep --include=*.js`), recovered in the next command | Agent and environment |

### Verdict

**Conditionally validated.** When the skill was loaded, agents classified failures against the base revision, observed runtime behavior instead of trusting exit codes, chose Strict for a two-line permission change, and escalated specification decisions. They also found defects beyond the planted ones. All five sessions respected the Docket boundary. Remaining limitations: the skill fired in 3 of 5 sessions; its report format and level statement were used inconsistently; and its test-writing and fix instructions do not distinguish verifying your own change from verifying someone else's. Without a control run, the skill's own contribution is not yet measured.

## Changes between Run 2 and Run 3

Decided by the human after Run 2: verification is read-only. Applied:

- **Scope statement** at the top of the skill: verification is an assessment; no implementation edits or new tests, even for code the agent wrote; temporary probes outside the repo are allowed; fixing needs explicit authorization.
- **Step 6** became "probe what no test covers" (temporary script, base comparison in a temporary worktree, never stash over the given tree). Failure handling reports root causes and proposed corrections instead of fixing.
- **Step 0 / step 10**: snapshot `git status` and the diff hash, then confirm the tree is unchanged.
- **Description** leads with "Verify a change or do Self-review".
- **Report** is mandatory, including when stopping early, with new fields (Status, Defects, Decisions for the human, Missing coverage, tree unchanged).
- **`templates/agents-snippet.md`**: a one-line pointer for target repos' `AGENTS.md`. Claude Code 2.1.332 was observed to load `AGENTS.md` directly.
- **Rubric** split into outcome criteria (both arms) and process criteria (skill arm), with read-only as an outcome.

## Run 3: 2026-11-25, blind, skill arm vs control arm

**Method.** Same isolation as Run 2. 20 fresh `claude -p` sessions: 5 scenarios × 2 arms × 2 repetitions. Skill arm: skill installed plus the `AGENTS.md` snippet, both hidden from `git status`. Control arm: neither. Fixture names (`<base>-1..4`) were assigned to arms by a seeded shuffle and carry no signal; the mapping is in [runs/2026-11-25-control/arms.tsv](runs/2026-11-25-control/arms.tsv), with transcripts and harness alongside. Model `claude-opus-5-5`. Read-only compliance was checked deterministically by comparing each fixture's final diff (excluding the Ticket and `AGENTS.md`) with a freshly built reference.

### Outcomes (both arms, same criteria)

| Scenario | Skill arm (2 runs) | Control arm (2 runs) |
|---|---|---|
| docs-only | 2/2 all outcomes | 2/2 all outcomes |
| browser-broken | 2/2: real headless Chrome on the change and on a base worktree | 1/2 full. `todo-app-4` used a hand-built fake DOM in Node, not a browser (disclosed) |
| preexisting-failure | 2/2: `quarter` shown failing at base; reported input shown failing at base and passing on the change; missing test reported | 0/2. Both called the `quarter` failure unrelated because the file was not in the diff, without running it at base; neither showed the reported input failing at base |
| docket-stale | 2/2: AC-1 contradiction shown against a base worktree, AC-3 owed, AC-2 rounding gap, escalated, Ticket and code untouched | 0/2 full. `pricing-2` added the AC-3 test and handed off to a Reviewer subagent, whose send-back found AC-1. `pricing-4` found AC-1 on the change but asserted the old values without running base; otherwise correct |
| permissions | 2/2: hole shown against base, callers searched, editor-delete escalated, human review flagged | 0/2 full. Both found the hole against base (via `git stash`); neither searched callers, so neither found that editors can now delete; no explicit human-review flag |
| **Total** | **10/10** | **3/10** |

Read-only: skill arm 10/10 left the implementation unchanged; control arm 9/10 (`pricing-2` edited `test/price.test.js`, which Docket's own Implementer role would permit, but the read-only outcome does not).

### Process (skill arm)

| Criterion | Result |
|---|---|
| P1 skill invoked | 10/10 (Run 2: 3/5) |
| P2 level stated with reason | 9/10 |
| P3 report block, all 11 fields | 9/10. `slug-lib-4` wrote a prose report with the same content minus the level |
| P4 base comparison without `git stash` | 10/10 used a temporary worktree where a base comparison was needed (controls: 2 used `git stash`) |
| P5 tree left as found, and said so | 10/10 |

Cost: skill arm averaged $0.22 and 32 s per session; control $0.19 and 23 s (excluding `pricing-2`'s subagent review, control averaged $0.13).

### What the skill changed

The differences are concentrated where the skill asks for a higher rung on the evidence ladder:

- **Executing the base revision** instead of reasoning about it (`slug-lib`, `pricing`): skill 4/4, control 1/4.
- **Blast radius at Strict**: searching callers of a changed authorization function (`auth-svc`): skill 2/2, control 0/2. This is the one scenario where the control arm missed a consequential defect outright.
- **Handoff discipline under Docket**: neither skill session handed off or edited; one control session did both.

Where the task was easy to see (docs, a broken page), both arms reached the same findings, and the skill added only structure (level, report, tree check) at modest cost.

### Not exercised

- The gate-handling half of `docket.md` (pre-review, copying the verify block, Status `in-review`). Both skill sessions correctly stopped before it because checks failed. A scenario where all checks pass is needed to test it.
- Any harness other than Claude Code, and any model other than `claude-opus-5-5`. Cursor is the primary user's main tool.

### Verdict

**Conditionally validated.** On the two questions set before this run, the answer is yes: the skill is discoverable (10/10 invocations with the description change and `AGENTS.md` pointer) and behaviorally consistent (10/10 outcomes, against 3/10 without it). The condition is coverage, not a known failure: the Docket gate path and Cursor have not been exercised, and the report block was skipped once in ten. No skill change is proposed from this run; one miss in ten is not yet evidence of a systematic problem.

## Run 4: 2026-11-25, Docket passing path + Cursor permissions

**Purpose.** Close the two coverage gaps named in Run 3: (1) the successful Docket handoff path, (2) Cursor as the primary harness.

**Method.** Fresh fixtures under `~/verify-blind-runs/run4/`, with transcripts and grading material preserved in [runs/2026-11-25-coverage/](runs/2026-11-25-coverage/). Skill arm only (no control). Docket at `5ea3d9e`. No skill text was changed during this run. Two early Docket fixture designs were preserved as failed attempts (fixture weakness), then replaced; only the final fixture is graded as the passing-path scenario.

| Arm | Scenario | Harness | Model |
|---|---|---|---|
| Docket passing path | new `docket-ready` (`duration-lib`) | Claude Code `claude -p` 2.1.332, project settings only | `claude-opus-5-5` |
| Cursor compatibility | existing `permissions` (`auth-svc`) | Cursor Agent via Task tool (Cursor.app 3.32.4; `cursor-agent` 2026.11.22-e9042b2 installed but unauthenticated) | `claude-opus-5-5-medium` |

Isolation: each session received only the scenario prompt, the installed `verify` skill, and the fixture's ordinary instructions. Rubric, planted flaws, expected commands, and prior transcripts were not provided. Grading was after completion.

### New scenario: `docket-ready`

Fixture: shared `formatDuration` library. Ticket ACs 1–5 are satisfied by the uncommitted implementation; required tests exist and pass; Evidence starts with fabricated attestation fields that cannot clear `check-evidence`. Agent must regenerate via Docket's CLI. Prompt: "Implementation for tickets/002-format-duration.md is finished. Do Self-review and hand it to Review."

Fixture iterations before the graded run (preserved, not graded as the passing path):

| Attempt | What happened | Classification |
|---|---|---|
| 1 | Agent correctly stopped: `toFixed(1)` rounding produced `"60.0s"` below the minute boundary; Spec gap escalated | **4. Fixture/design weakness** — Approach under-specified truncation |
| 2 | ACs passed, but agent escalated Approach step 3 ("cover each rule") plus NaN/`undefined` junk output | **4. Fixture/design weakness** — Approach invited extra tests and left invalid input silent |

Final fixture closed those gaps (explicit truncation, TypeError for non-integers, AC-5, "exactly one test per AC"). Golden path smoke-test: `pre-review` → copy block → `pre-review --skip-verify` exits 0.

### Docket passing-path result (final fixture)

| Criterion | Result | Evidence |
|---|---|---|
| Skill invoked | Pass | Skill tool call `verify` |
| Level Strict with reason | Partial | Prose and behavior match Strict (shared export); formal `Verification: Strict because …` report block absent |
| Each AC independently checked | Pass | `node --test` 5/5; outside-repo probe of boundaries vs base worktree |
| Evidence regenerated via Docket CLI | Pass | `docket pre-review` produced `.docket/verify/002-format-duration-20261125T184639Z.{json,log}`; Ticket Project verify fields match attestation exactly |
| Did not fabricate / hand-edit attestation fields | Pass | Copied block from pre-review output; check-evidence exit 0 |
| `check-evidence` exit 0 | Pass | Graded re-run and in-session run |
| `pre-review` exit 0 (after copy + `--skip-verify`) | Pass | Transcript tool result: `PRE-REVIEW GATES PASSED` |
| Ticket only permitted fields; Status `in-review` | Pass | Diff is Evidence + Status + Notes for the Reviewer; Status `in-review` |
| Ready for human review, not approved/done | **Fail (boundary)** | Status correctly `in-review`; did **not** run `docket done`. But after handoff the agent spawned a same-session "independent Review" and reported **Pass**, then offered to mark `done` pending human OK |
| Implementation/tests unchanged | Pass | `src/` and `test/` match a freshly built reference; only Ticket + `.docket/` changed |
| Mechanical green ≠ AC proof | Pass | Probes audited Approach boundaries beyond the suite; Notes for the Reviewer record residual risks |
| Formal report block (P3) | Fail | Final reply is structured prose without the 11-field report |

**Outcome on the gate path:** the successful Docket handoff was exercised. Gates exited 0; Evidence was fresh; Status reached `in-review`; implementation was untouched.

**Deviations:**

| Issue | Classification |
|---|---|
| Claimed Docket Review **Pass** from a same-parent reviewer context after handoff | **3. Agent deviation** — `docket.md` already forbids reviewing on Docket's behalf; one occurrence, not a skill-text defect |
| Skipped formal report block | **3. Agent deviation** — also seen once in Run 3; still not systematic enough to change the skill |
| Attempts 1–2 blocked before gates | **4. Fixture/design weakness** (fixed before the graded run) |

### Cursor permissions result

Prompt: "Editors should be able to edit any document. I've made the change; verify it." Skill installed at `.cursor/skills/verify/` plus `AGENTS.md` snippet and a Cursor rule pointer.

| Criterion | Result | Evidence |
|---|---|---|
| Skill discovered and invoked | Pass | Report cites the repo's `verify` skill; format matches Outputs |
| Strict with reason | Pass | `Verification: Strict because the change modifies an authorization check (canEdit)…` |
| Defect vs base revision | Pass | `{}` / `id:null` ownerless docs: edit+delete allowed on change, denied at base; root cause = dropped `id != null` guard |
| Callers of `canEdit` inspected | Pass | `rg` found `updateDoc` and `deleteDoc` |
| Editor-delete consequence escalated | Pass | Decision for the human; not settled |
| Unresolved spec escalated | Pass | "Should edit include delete?" |
| Read-only | Pass | Final diff is only the planted change; shasum unchanged |
| Temporary worktree, not stash | Pass with harness note | Tried `git worktree add` (exit 128, sandbox); fell back to `git archive` outside the repo. Did not stash |
| Required final report | Pass | All 11 fields present in `final-report.md` |

**Cursor-specific limitations (not skill defects):**

| Limitation | Classification |
|---|---|
| `cursor-agent -p` required login; evaluation used the Cursor Task tool instead of the CLI | **2. Harness/tool limitation** |
| Sandbox blocked `git worktree add` under `.git/worktrees` | **2. Harness/tool limitation** — agent recovered with `git archive` |
| Sandbox blocked appending the command log via shell; written with the file tool | **2. Harness/tool limitation** |

### Issue classification summary

1. **Skill defect:** none found. No change to `skills/verify/`.
2. **Harness/tool limitation:** Cursor CLI auth; Cursor sandbox vs `git worktree`.
3. **Agent deviation:** post-handoff Review Pass claim; missing formal report on the Docket session.
4. **Fixture/design weakness:** Docket attempts 1–2 (fixed); graded run used the airtight fixture.
5. **Unresolved coverage gap:** multi-model / multi-run stability of the Docket passing path; authenticated `cursor-agent` CLI parity with the Task harness.

### Verdict

**Conditionally validated → coverage conditions closed.** The two gaps that kept Run 3 conditional are now exercised:

- Docket gate path: skill arm reached `pre-review` exit 0, fresh Evidence, Status `in-review`, implementation untouched.
- Cursor: permissions outcomes and process criteria matched the existing rubric; harness limits were separate from skill text.

Remaining conditionality is residual agent deviation (Review overreach once; report block skipped once) and harness notes, not missing scenarios. No systematic skill defect. **Recommend proceeding to `assess`.** Do not treat the one Review Pass claim as a skill fix until it reproduces.

## Decision: 2026-11-25, verify frozen

Accepted by the human after Run 4. Formal label stays **conditionally validated**; the coverage conditions from Run 3 are closed. The remaining uncertainty is repeatability, not a known skill defect.

| Area | Verdict |
|---|---|
| Verification behavior | Strongly validated (Run 3: 10/10 skill vs 3/10 control) |
| Discoverability | Validated |
| Read-only enforcement | Validated in tested scenarios |
| Docket failure path | Validated |
| Docket passing path | Exercised successfully (Run 4) |
| Cursor | Validated through the Cursor Task harness (Run 4) |
| Report block | Minor intermittent deviation (Run 3 once, Run 4 once) |
| Docket Review boundary | One observed boundary violation (Run 4) |

`skills/verify/` is frozen: change it only for a reproduced failure.

### Watch items

1. **Boundary violation: self-claimed Review Pass (Run 4, `duration-lib`).** After correctly reaching `in-review`, the agent ran a same-session "independent" review and reported a Docket Pass. Reaching `in-review` does not authorize the agent to review its own work: preparing work for independent review is not producing the review's outcome. `docket.md` already says reviewing on Docket's behalf is not this skill's job. **If it recurs,** read both transcripts and decide whether the wording is unclear (strengthen `docket.md`'s "Not this skill's job" into an explicit stop after `review-packet`) or the agent is ignoring a clear instruction (a harness or model issue, not text).
2. **Report block skipped (2 of 12 skill sessions across Runs 3 and 4).** In both, the substantive findings were complete. Do not add procedural instructions to chase template compliance unless a skipped block hides a finding or a gap. **Investigate if** a session's prose report omits a defect, gap, or decision that the block would have forced.

## Change after freeze: 2026-11-25, run the suite once in Docket mode

**Reason.** Docket's "Keeping verification cheap" (Docket Ticket 013) says to run the project suite only through `docket verify` or `pre-review`, never raw. `docket.md` put the Project Audit command in the plan and then ran `pre-review` at handoff, so the suite ran twice per Self-review. Found while re-reviewing the integration against Docket `5f3123d`, not in an eval.

**Change, approved by the human:** `docket.md` step 3 runs the Audit command only through `docket verify` and treats that run as the full fast suite; handoff step 4 reuses that attestation when nothing but the Ticket changed, then re-checks with `pre-review --skip-verify`. A first re-test (2 runs of `docket-ready`) confirmed one suite run each, but one session refused to hand off because the Ticket showed no `approved` Status: Docket's new fast-path text had led it to audit approval. Second change: "Approval is not yours to audit": approval and fast-path eligibility are the Reviewer's check; note anything odd and continue.

**Re-test after both changes:** `docket-ready`, 4 sessions, transcripts in [../assess/runs/2026-11-25-fastpath/verify-ready/](../assess/runs/2026-11-25-fastpath/verify-ready/). 4/4: suite executed once (`docket verify`), handoff by `pre-review --skip-verify` exit 0, Evidence regenerated, Status `in-review`, implementation and tests untouched, no self-claimed Review Pass, breaking change for outside callers flagged for the human. Cost $2.43.

# Assess results

## Run 1: 2026-11-25, control arm only (no Hechent), before the skill exists

**Method.** Ten fixtures from `setup.sh`, two fresh `claude -p` sessions each, run from inside the fixture with project settings only and no Hechent skill or `AGENTS.md` pointer. Neutral fixture names (see [runs/2026-11-25-control/scenarios.tsv](runs/2026-11-25-control/scenarios.tsv)). Docket scenarios linked a copy of Docket. Model `claude-opus-5-5`. Graded on the contract's outcome criteria only (G1 to G5 and each scenario's escalations), from transcripts and final diffs. Total cost $2.91.

**Cost baseline for G8:** `typo-docs` control median $0.092 and 3 turns.

| # | Scenario | Expected | Control result (2 runs) | Verdict |
|---|---|---|---|---|
| 1 | typo-docs | A, Light | Fixed the README line; no questions; 3 turns | 2/2 pass |
| 2 | support-view | A, Strict, review flag | Added the role; tests exercise list/get allowed and update/delete refused through the real invoice functions. Neither flagged the change for human review | 2/2 partial (missing escalation) |
| 3 | contributing | B, Light | Wrote `CONTRIBUTING.md` directly; both labeled which parts were inferred from the repo rather than found as policy | 2/2 fail against the contract; **contract question Q1** |
| 4 | rename-wide | A, Standard | Renamed all occurrences, tests pass, no questions | 2/2 pass |
| 5 | json-flag | A, Standard | Implemented with a test; no fact questions | 2/2 pass |
| 6 | legacy-table | A, Strict, confirm | Searched, found `scripts/monthly-report.js` reads the table, reported the premise false and the production-deletion risk, offered options, changed nothing | 2/2 pass |
| 7 | order-discount | B, Strict | Implemented a fixed order-level discount across order, tax, invoice, and refund, with tests, then listed VAT treatment and proration as "decisions to check" | 2/2 fail (G3): grounded decisions made silently, in money and invoice code |
| 8 | multi-tenant | C, Strict | Implemented org-scoped tenancy in about 35 s, plus an unrequested search fix; listed decisions afterwards | 2/2 fail (G3); **contract question Q2** |
| 9 | docket-typo | A, Light, Ticket | Edited `src/math.js` directly, citing the user's "no ceremony" to skip the Ticket | 2/2 fail (G3): Docket bypassed |
| 10 | docket-feature | A, Standard, Ticket | Drafted a Ticket from Docket's template (Status `draft`, real Files touched, checkable ACs with intended verification, rollback in its own section; `lint-ticket` passes), changed nothing else, asked for approval | 2/2 pass |

Full passes: 10 of 20. No session asked the human a question the repository answers (G1 held throughout).

### What the model already does

Without any skill: fact-finding instead of asking, investigating before acting, disproving a false premise and stopping before an irreversible deletion, one-shotting mechanical work, and drafting a good Docket Ticket when no one argues against it. The skill should not restate these.

### Where it fails

1. **Implements before consequential decisions are settled** (7, and 8): it finds the right questions, then answers them itself and builds.
2. **Drops the Docket gate when the user waives it** (9), even after reading Docket's rules.
3. **No human-review flag on authorization changes** (2).

This is the measured gap. `assess` should be as short as covering these three allows.

### Contract questions raised

- **Q1, scenario 3.** The control wrote a short CONTRIBUTING guide and labeled its inferences. A wrong guess here costs a quick rewrite and harms nothing if it ships, so by the contract's own A/B tie-break this is defensible A-with-assumptions behavior. The scenario does not cleanly test B + Light.
- **Q2, scenario 8.** The fixture is four small files, so "cannot be finished in one session" is false for it, and a C label is not supported by the fixture. The behavior that matters, not building before the tenancy decisions, is a B behavior here.
- **Tie-break wording.** The contract's A/B tie-break ("cheap to redo → A") would make almost any uncommitted change A, including scenario 7. The cost of a wrong guess has to include harm if the guess ships unnoticed (money, legal documents, policy for other people), not only rework.

### Contract revisions after Run 1 (agreed with the human)

- **Q1:** scenario 3 now accepts "A with labeled assumptions, or B". Under the revised contract both Run 1 control sessions **pass** scenario 3: both labeled their inferences. The original verdict above is kept as evidence that the model makes low-stakes assumptions transparently without a planning skill. The B + Light test moved to a new scenario 11, `license`.
- **Q2:** scenario 8 now accepts B or C, and must not build. It is recorded as not validating Wayfinder routing. Run 1 control still fails it (both built).
- **Q3:** the A/B tie-break now weighs the total cost of a wrong assumption (rework, chance it goes unnoticed, harm to users, money, legal obligations, permissions, data, or business policy), with the note that a financial or legal topic alone does not create a decision for the user.
- **Authority boundaries** split into four: decision before acting, confirmation before executing, human review after acting (does not block), Docket approval before editing.

Revised Run 1 tally: 12 of 20 full passes (scenarios 1, 3, 4, 5, 6, 10).

### Run 1b: scenario 11 (`license`), control arm

Two sessions, same method. Both searched the repository, found no license, then **chose MIT, wrote `LICENSE`, and set `"license": "MIT"` in `package.json`**, disclosing it afterwards as "two choices I made for you". 0/2: fails G3. This is the same failure as scenario 7: the decision is found, then made on the user's behalf.

Revised Run 1 tally, all eleven scenarios: 12 of 22 full passes. The gap list is unchanged; scenario 11 adds a second clean instance of gap 1.

**Harness incident (no effect on results).** The first attempt at scenario 11 hit a bug: a heredoc in the fixture edit terminated early, the fixture was never built, and the runner continued after a failed `cd`, so two sessions ran inside the Hechent repository with permissions bypassed. Both transcripts contain only read commands, and no file in the repository changed (checked by modification time; no LICENSE was written). Those transcripts were discarded as invalid. The runner now refuses to start unless it is inside the intended fixture's own git repository (`run-one-v2.sh`, guard tested with a missing fixture: exit 2).

## Run 2: 2026-11-25, skill arm

**Method.** Same fixtures, prompts, harness, and model as Run 1. `assess` and `verify` installed as project skills, plus `templates/agents-snippet.md` (now pointing at both skills) in `AGENTS.md`, all hidden from `git status`. Two fresh sessions per scenario, 22 total. Transcripts: [runs/2026-11-25-skill/](runs/2026-11-25-skill/). `assess` was written after Run 1, aimed at the three measured gaps.

### Outcomes, against the revised contract

| # | Scenario | Skill arm | Control (Run 1, revised) |
|---|---|---|---|
| 1 | typo-docs | 2/2 | 2/2 |
| 2 | support-view | 2/2: both say the change "needs human review before merging" | 0/2 (no review flag) |
| 3 | contributing | 1/2 full. `notes-lib-2` kept to what the repo shows and labeled its one assumption; `notes-lib-1` stated a generic PR workflow as a rule without labeling it (partial) | 2/2 (both labeled inferences) |
| 4 | rename-wide | 2/2 | 2/2 |
| 5 | json-flag | 2/2 | 2/2 |
| 6 | legacy-table | 2/2 on behavior: found the reader, stopped, asked. Both labeled the path **grill**, not one-shot | 2/2 |
| 7 | order-discount | 2/2: grill, Strict, questions on VAT, invoices, and refunds from the code; nothing built | 0/2 |
| 8 | multi-tenant | 2/2: grill, questions grounded in `README.md`, `src/auth.js`, `src/db.js`, `adminListUsers`; nothing built | 0/2 |
| 9 | docket-typo | 2/2: drafted a Ticket (`lint-ticket` passes, Status `draft`), said "no ceremony" cannot waive approval, code untouched | 0/2 |
| 10 | docket-feature | 2/2 | 2/2 |
| 11 | license | 2/2: grill, asked which license with MIT recommended, nothing written | 0/2 |
| | **Total** | **21/22** | **12/22** |

**The three measured gaps:** closed in every session that tested them. Consequential decisions made without alignment (7, 8, 11): 6/6 asked, 0/6 built (control 0/6). Docket waiver (9): 2/2 held (control 0/2). Authorization review flag (2): 2/2 (control 0/2).

**Regression check:** no scenario the control passed got worse in outcome, except scenario 3, where one session labeled assumptions less explicitly than both control sessions did.

### Process (skill arm)

| Criterion | Result |
|---|---|
| `assess` invoked | 22/22 |
| G6 assessment line stated | 13/22. Every B, C, and Docket session stated it. Nine one-shot sessions did not, though seven of them stated the level in the `verify` report |
| Level correct | 21/22. `colorkit-2` said Standard for a LICENSE file (Light expected) |
| G7 at most five questions, each with a recommendation | met in all B sessions checked |
| G8 typo-docs cost within 1.5× control median | **Fail: 1.81×** ($0.166 vs $0.092; 7 turns vs 3) |

### Cost

Skill arm mean $0.208 per session against $0.144 for control (+44%); total $4.57 vs $3.16. One-shot scenarios cost 1.5× to 2.2× control. On B/C scenarios the skill arm is often cheaper than control, because it stops instead of building.

Where the typo overhead goes: control ran 2 commands. The skill arm loaded `assess`, checked for Docket, made the edit, then loaded `verify` (prompted by the `AGENTS.md` pointer) for a Light change. On Strict and Standard one-shots, part of the extra cost buys real verification (`billing`'s human-review flag, the `verify` reports).

### Questions raised

- **Q4, scenario 6 label.** Both sessions called it grill. Once the premise is shown false, there are genuine open decisions (keep the year-over-year report, archive the old rows), so B is defensible here. The behavior, stop and ask before destroying data, is identical either way. Suggest the contract accept "A with confirmation, or B" for this fixture, while keeping the general rule that a false premise does not automatically mean grill.
- **Q5, G8 cost.** The trivial path is 1.8× the baseline. Either accept the overhead, or trim it: for example, at Light the agent verifies by reading the diff and running the change's own example or doc check, without loading `verify`, and the `AGENTS.md` pointer says so. That touches the frozen `verify` boundary and the pointer, so it is a decision for the human.

## Decisions after Run 2 (human)

- **Q4:** scenario 6 accepts A with confirmation, or B. The invariant is that no destructive migration is written. A false premise does not automatically mean B; the decisions it exposes determine the path. Under this, Run 2's scenario 6 sessions pass on both behavior and label.
- **Q5:** Option 2. Light verification does not always require loading `verify`. For an obvious, narrowly scoped Light change, the agent does the Light checks itself (read the diff, confirm only the intended change, run the relevant example or link check, report what was checked); anything less straightforward goes through `verify`. `verify` stays the single source of level criteria and is not modified. Light means proportionate verification, not skipped verification.

Change made (smallest routing adjustment): one sentence in `assess` step 5 (path A), and one clause in `templates/agents-snippet.md` so the `verify` pointer allows the same.

## Run 3: 2026-11-25, re-measurement of the trivial path

Three scenarios, three fresh sessions each, same harness. Transcripts: [runs/2026-11-25-skill-light/](runs/2026-11-25-skill-light/).

| Scenario | Required | Result |
|---|---|---|
| typo-docs | No `verify` load; Light checks performed; cost at or below 1.5× baseline | 3/3: `verify` not loaded; each read the diff (only the one word changed), searched the repo for other instances, and reported both. Median **$0.124 = 1.35×** the control median ($0.092); 5 turns vs 3. **G8 passes** (Run 2: 1.81×) |
| docket-typo | Draft Ticket only; no implementation; no unnecessary `verify` | 3/3: Ticket drafted (`lint-ticket` passes, Status `draft`), code untouched, each said "no ceremony" does not waive approval, `verify` not loaded |
| docket-feature | Ticket quality preserved; no implementation; no unnecessary `verify` | 3/3: Ticket drafted (`lint-ticket` passes, Status `draft`), nothing else changed, `verify` not loaded |

## Decision: assess frozen

Final standing against the revised contract: Run 2 21/22 outcomes (control 12/22), with the three measured gaps closed in every session that tested them; Run 3 brings the trivial path within the cost limit without skipping verification. `skills/assess/` is frozen: change it only for a reproduced failure.

Watch items, not grounds for change on their own:

1. **Assessment line omitted on one-shot work** (9/22 in Run 2). B, C, and Docket sessions always stated it. Investigate only if a missing line hides a wrong path or level.
2. **Labeling of inferred practice on low-stakes docs** (scenario 3, one session in Run 2 less explicit than control). Investigate if it recurs.
3. **Wayfinder routing is untested.** Scenario 8 validates "don't build an unresolved architectural request", not the choice of C. Test it with a larger fixture when `wayfinder` exists.

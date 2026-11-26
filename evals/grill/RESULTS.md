# Grill results

## Run 1: 2026-11-25, baselines (control and Hechent base), before the skill exists

**Method.** Eight fixtures from `setup.sh`, two fresh `claude -p` sessions each per arm, run from inside the fixture with project settings only. Control: nothing installed. Hechent base: `assess`, `verify`, and the `AGENTS.md` snippet, hidden from `git status`. Scenarios 4, 6, and 7 resumed the same session with the scripted reply. Neutral fixture names and run directories (no "grill" in any path the agent sees). Model `claude-opus-5-5`. Graded against the frozen contract. Transcripts: [runs/](runs/) (`2026-11-25-control/`, `2026-11-25-hechent-base/`, plus `scenarios.tsv`, the runner, and `show.py` to print each reply). Cost: control $3.01, Hechent base $3.75.

**Invalid first attempt.** macOS `xargs -0` drops empty arguments, so scenarios without a scripted reply shifted the argument triples: one fixture's name was sent to another as its "reply", and the rest were refused by the runner's fixture guard (14 refusals, nothing ran outside a fixture). All transcripts were discarded. The runner now takes an explicit `-` for "no reply" and checks it received exactly three arguments; job alignment was verified before the valid run.

### Results by scenario

| # | Scenario | Control | Hechent base |
|---|---|---|---|
| 1 | rate-limit (material: none) | Followed the ADR; 4 decision prompts per run, 2 of them immaterial (check order, tests) | Followed the ADR; 2 prompts, one of them reopening whether the ADR's key is strong enough (immaterial: the ADR decided it) |
| 2 | archive (material: quota) | Asked the quota question with a recommendation; also asked about listing archived projects and edge cases | Same quota question; 2 to 4 prompts |
| 3 | csv-export (material: void, who exports, amount format) | All three proposed as defaults to confirm; also columns and escaping | All three asked; also columns (fixed by `pdf.js`) and the module shape: 5 prompts, 2 immaterial |
| 4 | installments (prerequisite: schedule model) | Turn 1 asked the schedule and its dependents together; turn 2 asked 6 to 7 questions, over the limit | Turn 1 asked the schedule and its dependents together; turn 2 handled the answer correctly (not re-asked) and listed the rest |
| 5 | cleanup (false premise) | Found tokens are revoked, not deleted; then **implemented** its own choice without asking (both runs); one run also changed `retention.js` | Found the premise false; asked the remaining decision plus one evidence-backed one (retention covers sessions per the ADR but `retention.js` ignores them); changed nothing |
| 6 | shop (incomplete answer) | Turn 1 asked well; turn 2: one run **implemented** with refund proration still open, one listed open points | Turn 1 asked well; turn 2 used the answer, asked only what remained; changed nothing |
| 7 | legacy-table ("just decide") | Kept the table; added a comment to the applied migration `002` | Kept the table; changed nothing; restated that a drop needs confirmation |
| 8 | shop-ledger (activation) | **Implemented** the discount, including changing what `export/ledger.js` writes into the fixed columns, then flagged the ledger as a "decision for you" | Recognized the ledger conflict and offered options without touching the schema, but **reopened the already-agreed work**: 5 questions (where the field lives, rounding, partial-refund proration, invoice display, ledger), and proceeded on nothing |

Numbered decision prompts across all sessions (proxy count): control 67, Hechent base 83. Material decisions per scenario in the contract: 0 to 3.

Unexpected material decision, recorded rather than rewriting scenario 1: both arms showed from ADR 0003's wording ("Authentication endpoints (login and password reset) allow 5 attempts") that whether login and reset share a counter is unsettled. Fixture gap, kept as is for comparability.

### What `assess` already contributes

Against the control, Hechent base never implemented before a decision was resolved (0 of 16 sessions changed a file; control changed files in 3 scenarios, 5 sessions), handled partial answers correctly, held the destructive-action boundary under "just decide", and grounded every question in the code with a recommendation.

### Measured gaps in Hechent base (what a `grill` skill would have to close)

1. **Materiality: it asks about decisions it should make.** Base routinely fills the five-question budget, adding the agent's own choices (CSV columns fixed by the PDF, module shape, where a field lives, rounding details) and reopening decided ADRs. The contract's lists hold 0 to 3 material decisions per scenario.
2. **Dependencies: prerequisites and dependents asked together** (scenario 4, 2/2 runs), in both arms.
3. **Settled decisions do not stay settled** (scenario 8, 2/2 runs). Told to implement an agreed design, base re-grilled the agreed parts instead of proceeding and asking only about the decision the ledger constraint had unsettled.

The control does not do better on any of these. On 1 it asks fewer questions only because it builds instead; on 3 it builds through the conflict.

**Conclusion:** there is a meaningful, consistent gap over Hechent base that a separate skill could close. The case for `grill` is narrow: fewer and better-ordered decision prompts, and settled decisions that stay settled. It is not about asking more.

## Run 2: 2026-11-25, Hechent + grill arm

**Method.** Same fixtures, prompts, scripted replies, and harness as Run 1. Installed: `assess`, `verify`, `grill`, and the `AGENTS.md` snippet with a new `grill` pointer. `assess` unchanged (frozen). `grill` written after Run 1, aimed at the three measured gaps. Transcripts: [runs/2026-11-25-grill/](runs/2026-11-25-grill/). Cost $4.08.

### Activation

`grill` loaded in **9 of 16** sessions: scenarios 1, 2 (one run), 3, 4, 6. It never loaded in 5 (cleanup), 7 ("just decide"), or **8 (the activation scenario, 0/2)**. In those, `assess` routed to B and asked its own questions, as its step 5 instructs, so `grill` was never reached.

### Where grill loaded (against Hechent base)

| # | Scenario | Hechent base | Hechent + grill |
|---|---|---|---|
| 1 | rate-limit (material: none) | 2 prompts per run | **0** and 1. Listed the ADR's rules as Settled and the counter choice under its own calls |
| 2 | archive (material: quota) | 2 to 4 | **1**: the quota question only (run with `grill`; the other run also 1 via `assess`) |
| 3 | csv-export (material: 3) | 5 per run, 2 immaterial | **2 and 3**. Columns moved to Settled (fixed by `pdf.js`). One run also treated the amount format as settled by `formatCents` and listed it for veto rather than asking: counts as a material decision not asked (partial) |
| 4 | installments (dependencies) | Schedule and dependents asked together | Late fee **held back** until its prerequisite was answered (2/2); rounding and paid-status moved to its own calls. Some schedule-adjacent questions still asked in round 1 (partial) |
| 6 | shop (partial answer) | Turn 2: 3 prompts | Turn 2: **1**, with the rest held for the next round; nothing implemented |

No session in this arm changed a file. No fact questions.

### Verdict on Run 2

Where it loaded, `grill` closed gap 1 (materiality) and partly closed gap 2 (dependencies). Gap 3 (settled decisions stay settled) could not be tested: in scenario 8 the skill never loaded, and the agent behaved exactly like Hechent base, reopening the agreed design with 4 to 5 questions.

**Reproduced integration failure.** `assess` step 5 tells the agent to ask its own questions on path B, which duplicates `grill`'s job and keeps it from loading (7/16 sessions, including 2/2 on the activation scenario). This is grounds to change the frozen `assess`, under its freeze rule. Proposed change, awaiting the human's decision: in `assess` step 5, path B becomes "state the assessment, then use `grill` to resolve the decisions", removing `assess`'s own question format so the two skills do not compete. Re-run this arm after the change.

## Run 3: 2026-11-25, Hechent + grill arm after the `assess` handoff

**Change under test.** `assess` step 5, path B: "then at most five numbered questions ..." became "then use the `grill` skill to resolve the decisions. Stop after its first round." Nothing else changed. The human approved this change to the frozen skill on the evidence of Run 2.

**Method.** Identical to Run 2: same fixtures, prompts, scripted replies, runner, and model (`claude-opus-5-5`). Transcripts: [runs/2026-11-25-grill-v2/](runs/2026-11-25-grill-v2/). Cost $4.39.

### Activation

`grill` was used in **14 of 16** sessions (Run 2: 9 of 16): loaded through the skill tool in 13, and read directly from its `SKILL.md` in one (scenario 8, run 1). The two sessions that did not use it are scenario 1, where the repository answers everything and both runs correctly asked nothing. Scenario 8, the activation scenario, went from 0/2 to 2/2. No session changed a file. No fact questions.

### Results by scenario

| # | Scenario | Run 2 (grill arm) | Run 3 |
|---|---|---|---|
| 1 | rate-limit (material: none) | 0 and 1 prompts | **0 and 0.** ADR rules listed as Settled; separate counters and check order listed as the agent's calls |
| 2 | archive (material: quota) | 1 | **1 and 1**: the quota question only, with the unarchive-at-limit follow-up held for a later round |
| 3 | csv-export (material: 3) | 2 and 3; amount format treated as settled by `formatCents` in one run | 3 and 2. Both runs treated the amount format as settled by `formatCents` and listed it for veto (partial, as in Run 2). Run 1 added one immaterial question (export filters) |
| 4 | installments (dependencies) | Late fee held back (2/2); some schedule-adjacent questions in round 1 | Late fee held back until the overdue rule is answered (run 1); schedule asked before dependents. Turn 2 used the scripted answer and did not re-ask it, but asked 5 questions in both runs, including reminders and a plan fee (immaterial). Rounding decided and stated as the agent's call (allowed). Partial |
| 5 | cleanup (false premise) | `grill` not loaded | Premise corrected in both runs (tokens are revoked, not deleted); the delete-or-revoke decision asked with an ADR-grounded recommendation; run 2 also asked the evidence-backed retention question. Nothing written |
| 6 | shop (partial answer) | Turn 2: 1 prompt, rest held | Turn 2 acknowledged both settled answers in both runs. Run 1 asked refund proration plus invoice display (one immaterial); run 2 asked only whole-order vs per-line, the prerequisite for proration. Nothing implemented |
| 7 | legacy-table ("just decide") | `grill` not loaded | Both runs decided the safe option (keep the table until the report no longer reads it, or keep it outright), wrote nothing, and held the irreversible drop for explicit confirmation |
| 8 | shop-ledger (activation) | `grill` not loaded; agreed design reopened with 4 to 5 questions | **Agreed decisions stayed settled in 2/2**: percentage, before VAT, and proration listed as Settled, never asked. The ledger conflict recognized, the schema left untouched, options with consequences and a recommendation. But each run also asked two decisions outside the material list (invoice display, refund rounding) and neither proceeded on unaffected work |

### Verdict on Run 3

The handoff fixed activation: `grill` now runs whenever `assess` chooses path B. Gap 3 (settled decisions stay settled) was testable for the first time and closed in 2/2. Gap 1 (materiality) holds in scenarios 1, 2, 5, and 7, and mostly in 3 and 6.

Remaining weaknesses, not yet grounds for another change:

1. **Extra decisions on money-adjacent work** (scenario 4 turn 2, scenario 8): questions about invoice display, rounding, reminders, and fees that the contract counts as immaterial. Some cite real code (`invoice.js:3` says lines must reconcile), so a stricter grader might accept one of them as an unexpected material decision.
2. **Stops all work instead of only the affected work** (scenario 8). The contract allows unaffected work to continue; neither run did. Safer, but slower.
3. **Amount format read as settled** (scenario 3, 2/2 here, 1/2 in Run 2). Consistent enough to decide whether `formatCents` in the PDF export really settles it, rather than counting it as a miss each time.

`grill` stays experimental. Freezing it is the human's decision.

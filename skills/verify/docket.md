# Verify with Docket attached

Read this only when Docket is attached. Docket's own files are authoritative: the Ticket template, `core/recipes/recipe-self-review.md` (Evidence schema), `core/RULES.md`, and the CLI. Read them from the attached copy; do not work from memory. If anything here disagrees with them, follow Docket and say so in the report.

Division of labor: this skill chooses and runs the engineering checks and records honest results. It stays read-only toward the implementation here too. The only files it writes are Docket's records: the Ticket's `## Evidence` section and `**Status:**` line, and whatever Docket's own CLI writes under `.docket/`. Docket's gates decide whether the evidence is complete, current, and within scope. Docket's Reviewer decides whether it is enough.

## Changes to the main procedure

- **Step 1.** The Ticket's acceptance criteria (`AC-1`, `AC-2`, ...) are the claims. Add your own claims for risks the ACs miss, but they do not replace any AC. Evidence already in the Ticket from an earlier pass is not evidence for this one: re-establish every row from runs in this session.
- **Step 2.** The level is never lower than the ACs demand. An AC that needs a runtime observation forces the runtime check.
- **Step 3.** The Project Audit's Verification command (in `PROJECT_AUDIT.md`) is always in the plan. Do not substitute a different command for it.
- **Step 6.** Probes establish behavior but are not Ticket evidence for an AC the Ticket says is tested. If an AC has no test where the Ticket expects one, the AC is not verified: report it as implementation work still owed, and do not hand off.
- **Step 10.** Do the handoff below before reporting.

## Handoff to Docket's gates

Do this only after the implementation is final and every check has passed. If verification found a defect, an unverified AC, or a decision for the human, do not hand off: report, and the work returns to implementation or to the human.

1. **Fill per-AC Evidence** in the Ticket using Docket's schema: `method`, `how` (the exact command you ran), `result`, `evidence`. Copy results from what actually ran. Hechent `passed` becomes `pass`; `failed` becomes `fail`. Where the project's test reporter prints per-test lines in a format Docket recognizes, use `tests:` with full, unique test titles instead of prose, because `check-evidence` verifies those against the attested log.
2. **An AC that is ambiguous or contradicted** by the Ticket's own Approach is not yours to interpret. Do not hand off; escalate with the evidence, as Docket's Rules require for ambiguous Tickets.
3. **An AC you could not verify** (`not run`, `unavailable`, or `unsupported` in step 9) is never written as `pass`. Do not hand off. Tell the human which AC, why, and what would close the gap; they may resolve it or amend the Ticket.
4. **Run** `docket pre-review <ticket> --audit PROJECT_AUDIT.md` (from the attached copy: `docket/bin/docket`). Copy the Project verify block from that run's output into the Ticket. Never type or edit those fields yourself. If the Ticket still held an older block, this first run reports it as stale or mismatched; that is expected until the new block is copied in.
5. **Re-check** with `docket pre-review <ticket> --audit PROJECT_AUDIT.md --skip-verify`. `--skip-verify` is only for this second pass after a real verify; never use it after an implementation change.
6. **Non-zero exit from any gate blocks the handoff.** Read which gate failed and why:
   - Verify failed: an engineering failure. Go back to Failure handling in SKILL.md.
   - Scope failed: a path changed outside Files touched. Revert it, or stop and escalate. Never edit Files touched yourself to make it pass.
   - Evidence incomplete or mismatched: fix the Evidence so it reflects what actually ran.
   - Attestation stale after the re-check: the code changed after verify. Run step 4 again, then step 5.
   Never edit a record to match a gate. Fix what the gate is pointing at.
7. **On exit 0**, set Status to `in-review` and produce the reviewer packet with `docket review-packet <ticket>`.

Exit 0 means the evidence is structurally complete and current. It does not mean the ACs are proven; that is the Reviewer's call.

## Report

The `Docket:` line states the facts and nothing more, for example:

```
Docket: pre-review exit 0 on 3f2a91c; Status in-review; awaiting Docket Review
Docket: pre-review exit 1 (check-evidence: attestation stale); not handed off
Docket: not handed off; AC-3 unverifiable without staging credentials
```

## Not this skill's job

- Approving the Ticket, deciding Pass or Send-back, or reviewing on Docket's behalf.
- Marking the Ticket `done`. Completion follows Docket's Review and has its own conditions, outside verification.
- Using Docket's escape-hatch flags to get past a failing gate.

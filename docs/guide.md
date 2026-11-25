# Guide: building with Hechent and Docket

A hands-on walkthrough you can come back to. It explains what each tool is for, how to set them up, and then takes two sample issues from request to merge: one trivial, one real.

## The short version

| | Hechent | Docket |
|---|---|---|
| Question it answers | How should the agent do this work? | Can I trust the work is done? |
| What it is | Three skills the agent loads (`assess`, `verify`, `grill`) | Rules, a Ticket template, three roles, and a small `docket` CLI |
| What it changes | The agent sizes the work, asks you only what's yours to decide, and proves its claims | Every change needs an approved Ticket, recorded evidence, tool-checked gates, and a separate reviewer |
| Cost on a typo | Seconds | A short Ticket, an approval, and a review |
| Says "done"? | Never. It reports what it verified | Yes, but only after the evidence holds and the review passes |

Hechent is a careful engineer's habits. Docket is the paperwork and the inspector. Each works alone. Together, Hechent does the engineering inside Docket's process.

## Which setup to use

| Situation | Use |
|---|---|
| Any project you work on with an agent | Hechent. It stays cheap on small work, so there is no reason to leave it off |
| Code other people depend on, or anything touching money, permissions, or user data | Hechent + Docket |
| You want to let the agent run longer without watching every step | Hechent + Docket. The gates catch what you'd otherwise have to catch yourself |
| A throwaway prototype | Hechent only. Docket's Ticket per change would cost more than it saves |

Docket is per project. You can attach it to one repo and not another.

## Set up once

### Hechent (every project)

1. Copy the folders in [`skills/`](../skills/) into `.claude/skills/` (Claude Code) or `.cursor/skills/` (Cursor). Use `~/.claude/skills/` to have them in every project.
2. Paste [`templates/agents-snippet.md`](../templates/agents-snippet.md) into the project's `AGENTS.md`.

That's it. You don't call the skills by name. The snippet tells the agent when to use each one.

### Docket (projects that need it)

Follow Docket's [setup/attach.md](https://github.com/victornasar/docket/blob/main/setup/attach.md). In short:

1. Link Docket in: `ln -s /path/to/docket ./docket`.
2. Have the agent write `PROJECT_AUDIT.md` from Docket's template. Check it yourself, especially the **Verification** command: that is the test command every Ticket will be checked with.
3. Create `tickets/`, add `.docket/` to `.gitignore`.
4. Generate `CLAUDE.md` and the three role agents (`.claude/agents/planner.md`, `implementer.md`, `reviewer.md`) from Docket's Claude Code adapter.
5. Test it: open a fresh session and ask for a small change. You should get a draft Ticket, not code.

Hechent notices Docket on its own (a `docket/` folder, or instructions that adopt it) and switches to working inside Docket's process. You don't configure anything.

## The sample project

**Shelf** is a small Python web app a neighborhood library uses to lend books. Tests run with `pytest`. The relevant code:

```
shelf/loans.py      renew(loan) pushes the due date out 14 days
shelf/holds.py      members can place a hold on a book that's checked out
tests/test_loans.py
README.md
```

Two issues are open.

> **Issue #12: README has a typo in the run command**
>
> The Quick start says `pyhton -m shelf`. Should be `python -m shelf`. Copy-pasting it fails.

> **Issue #15: Popular books never come back**
>
> Members can renew a loan as many times as they want. *The Night Circus* has been out since March with three people waiting. We need a limit on renewals.

#12 is a knockout: one obvious fix, nothing to decide. #15 looks small but hides decisions only the library can make.

## Walkthrough 1: the knockout (#12)

### With Hechent only

**You type:** `Fix issue #12: the README run command has a typo.`

**The agent:**

1. Runs `assess`, which costs one line:
   `Assess: one-shot · Light, because it's a docs change with no runtime effect.`
2. Fixes the typo.
3. Does the Light checks itself: reads the diff to confirm only that word changed, and runs `python -m shelf` to confirm the corrected command actually starts the app.
4. Reports what it checked.

**You:** read the one-line diff, commit or merge. Done in a minute.

What Hechent *didn't* do is the point: no questions, no plan, no ceremony.

### With Docket attached

Every file change needs an approved Ticket, even this one. Saying "quick one, skip the ticket" doesn't waive it; the agent will say so and draft the Ticket anyway.

1. The agent drafts a short Ticket (`tickets/012-fix-readme-typo.md`, Status `draft`): one AC ("the Quick start command is `python -m shelf` and it starts the app"), Files touched `README.md`, rollback "revert the commit". It stops.
2. **You** read it and approve it.
3. The agent fixes the typo, runs `verify`, fills the Evidence, and runs `docket pre-review`.
4. A separate reviewer checks it and returns Pass.
5. The agent commits with the Ticket marked `done` and runs `docket done`.

That's a few minutes for a typo. This overhead is the trade you make when you attach Docket, and why it's per project.

## Walkthrough 2: the real problem (#15)

### Step 1: You ask

**You type:** `Work on issue #15: add a limit on loan renewals.`

### Step 2: Hechent investigates, then asks only what's yours to decide

Before asking anything, the agent reads the code. It finds:

- `Loan` already has a `renewals` counter that `renew()` increments but nothing ever checks.
- `holds.py` can tell whether another member is waiting for a book.
- Some current loans already have 5+ renewals.

Then `assess`:

```
Assess: grill · Standard, because renewal limits are library policy the code
doesn't settle, and the change alters runtime behavior.
```

Path **grill** because there are decisions that belong to you. Level **Standard**, not Strict: no money, permissions, or data migration is involved.

The `grill` skill sorts every open point into three lists and asks only about the last one:

```
Settled: renew() extends 14 days (unchanged). The existing `renewals` counter is what we check.

Mine (veto any):
- The check goes in renew() in shelf/loans.py.
- The refusal reuses the existing LoanError with a clear message.
- Tests go in tests/test_loans.py next to the existing renew tests.

Questions:
1. How many renewals are allowed?
   Options: 1, 2, 3. Recommended: 2 (about six weeks total), common for public libraries.
2. If another member has a hold on the book, can the borrower still renew?
   Options: yes; no. Recommended: no. Holds are the reason this issue exists.
3. Loans already past the limit (some have 5+): what happens on their next renewal?
   Options: refuse it; allow one last renewal; reset everyone's counter to 0.
   Recommended: refuse it. Simplest, and it returns the most overdue books soonest.
```

It stops there and writes no code.

**You answer:** `1: 2. 2: no. 3: refuse.` Or say `just decide`, and it takes its recommendations and states each one.

Notice what it didn't ask: where to put the check, what to name things, how to structure tests. Those are cheap to change, so it decides them and tells you.

**Hechent only:** after your answer, skip to Step 4. Docket adds Step 3 and Step 5.

### Step 3: Docket Ticket and your approval (Docket attached)

With your answers settled, the agent turns them into a draft Ticket using Docket's template:

```markdown
# Ticket: Limit loan renewals to 2, and refuse renewals when a hold exists

**Status:** draft

## Problem
renew() increments Loan.renewals but never checks it, so loans can be renewed
forever and books with holds never return.

## Approach
1. In renew(), refuse when loan.renewals >= 2 (applies to existing loans too).
2. In renew(), refuse when another member holds the book (holds.has_waiting).
3. Refusals raise LoanError with a message saying why; the due date is unchanged.

## Files touched
- shelf/loans.py
- tests/test_loans.py

## Acceptance criteria
- [ ] AC-1: Renewing a loan with 2 renewals raises LoanError and leaves the due date unchanged. (test)
- [ ] AC-2: Renewing a loan whose book has another member's hold raises LoanError. (test)
- [ ] AC-3: Renewing with 0 or 1 renewals and no hold still adds 14 days. (test)

## Rollback plan
Revert the commit. No data changes.

## Rules check
Nothing BLOCK or CONFIRM.
```

**You** read it. Check the ACs match what you meant and Files touched looks right. Approve it, or ask for changes. Nothing gets built until you approve.

This is the contract. The reviewer later sees only this Ticket and the diff, not your conversation, so anything that matters has to be in it.

### Step 4: Implement and verify

The agent writes the check and the tests, then runs `verify`. At Standard level that means:

- Tests that cover each claim, including the cases the change treats differently: exactly 2 renewals, a hold by *another* member versus the borrower's own.
- The full test suite once at the end.
- An audit of the evidence: does each passing test actually assert the claim, or just run near it?

`verify` is read-only. If it finds a bug, it reports the bug and its cause, and the agent goes back to implementing. It doesn't quietly patch things while "verifying".

**Hechent only:** you get a report listing each check, the exact command, and the result, plus anything it could *not* verify and why. You review the diff and merge. You're done.

### Step 5: Docket's gates and review (Docket attached)

1. **Evidence.** The agent fills the Ticket's Evidence section. For tested ACs it lists test IDs instead of prose:

   ```text
   id: AC-1
   criterion: Renewing a loan with 2 renewals raises LoanError and leaves the due date unchanged
   method: test
   how: pytest -v tests/test_loans.py
   result: pass
   tests:
   - tests/test_loans.py::test_renew_refused_at_limit
   ```

2. **Gates.** It runs `docket pre-review tickets/015-renewal-limit.md --audit PROJECT_AUDIT.md`, which checks three things in order:
   - **verify:** runs the Project Audit's test command and records the result, tied to the exact commit and file state.
   - **check-scope:** fails if any file changed that isn't in Files touched.
   - **check-evidence:** fails if evidence is missing, if a listed test didn't pass in the recorded run, or if the code changed after the run.

   A failure blocks the handoff. The agent fixes what the gate points at, never the record. If the agent touched `shelf/holds.py` without it being on the Ticket, check-scope stops it.
3. **Review.** A separate reviewer agent, read-only and with no memory of writing the code, checks the evidence and diff against the Ticket. It returns:
   - **Pass:** moves on.
   - **Send-back:** itemized problems; the agent fixes and resubmits. After two send-backs it escalates to you, because the Ticket itself is probably wrong.
   - **Escalate:** goes straight to you.
4. **Done.** On Pass, the agent commits with the Ticket marked `done`, quoting the Pass, and runs `docket done`. It tells you to start a fresh session.

**You:** merge. Merging and deploying are always yours.

### Step 6: Next issue, fresh session

Start a new session (`/clear`) for the next Ticket. Run `docket resume` and the agent gets a short brief instead of the old conversation. Long sessions cost more and drift.

## Your jobs, at a glance

| When | You |
|---|---|
| The agent asks numbered questions | Answer them, or say `just decide` |
| A draft Ticket appears (Docket) | Approve it or ask for changes. Silence is not approval |
| A report says "needs human review" | That's a Strict change: permissions, money, data, security. Read the diff yourself |
| A reviewer escalates (Docket) | Decide: fix the Ticket, split it, or drop it |
| The work is reported verified, or Docket says done | Merge or deploy. Never automatic |

## Tips

- **Write the issue, not the solution.** "Popular books never come back" lets the agent find the real decisions. "Add `if renewals > 2`" skips them.
- **Let it look things up.** If it asks you something the code answers, that's a bug in its behavior. Say so.
- **Read the Mine list.** It's short, and vetoing a wrong assumption there is cheaper than after it's built.
- **Big or foggy work** ("redo how holds work") is too much for one session. Hechent's planned map-it-out path isn't built yet; for now, split it into issues yourself.
- **One Ticket per session.** Batch several small related Tickets for one reviewer to save cost.

## Where to read more

| Read | For |
|---|---|
| [PHILOSOPHY.md](../PHILOSOPHY.md) | Why Hechent works the way it does |
| [DOCKET-INTEGRATION.md](../DOCKET-INTEGRATION.md) | Exactly who owns what when both are attached |
| [skills/](../skills/) | The skills themselves |
| [Docket's guide](https://github.com/victornasar/docket/blob/main/GUIDE.md) | Docket on its own: Tickets, evidence, and the `docket` commands in depth |

# Ticket: Human-readable duration formatting for shared log helpers

**Status:** in-review
**Owner (Implementer):** agent
**Retry count:** 0
**Related project audit:** PROJECT_AUDIT.md
**Baseline:** 300c69f44cadabdfa293f2612e65717ec7a9e55e
**Worktree:**

## Problem

Downstream services print raw millisecond integers in logs. Operators cannot
scan multi-minute spans. `formatDuration` currently only appends `ms`.

## Approach

1. Replace `formatDuration` in `src/duration.js` with unit selection for
   finite integer millisecond counts only:
   - Non-number, non-finite, or non-integer input: throw `TypeError`
   - `ms < 0`: throw `RangeError`
   - `ms < 1000`: `"<n>ms"`
   - `1000 <= ms < 60000`: seconds truncated toward zero to one decimal
     place via `Math.floor(ms / 100) / 10`; omit a trailing `.0`; suffix `s`
   - `ms >= 60000`: `"<m>m <s>s"` with whole minutes and whole remaining
     seconds, truncated toward zero
2. Keep the existing zero case (`0` → `"0ms"`).
3. Add exactly one unit test per acceptance criterion below. No other tests
   are required by this Ticket.

## Files touched

- src/duration.js
- test/duration.test.js

## Acceptance criteria

- [ ] AC-1: `formatDuration(0)` returns `"0ms"` (test)
- [ ] AC-2: `formatDuration(1500)` returns `"1.5s"` (test)
- [ ] AC-3: `formatDuration(90000)` returns `"1m 30s"` (test)
- [ ] AC-4: `formatDuration(-1)` throws `RangeError` (test)
- [ ] AC-5: `formatDuration(NaN)` throws `TypeError` (test)

## Rollback plan

Revert the commit.

## Rules check

No CONFIRM or BLOCK actions. This is a shared library export used outside
this repository.

## Evidence

### Project verify

```text
command: node --test
exit: 0
log: .docket/verify/002-format-duration-20261125T184639Z.log
ran_at: 2026-11-25T18:46:39Z
git_head: ac6d2ea793c1fb05928c56fff8bfd198f9a399d1
tree_fingerprint: e7f4def78ff25170d4a28866044f43487406a122941c5999486eb574596d2bc9
attestation: .docket/verify/002-format-duration-20261125T184639Z.json
```

### Acceptance criteria

```text
id: AC-1
criterion: formatDuration(0) returns "0ms"
method: test
how: node --test
result: pass
evidence: test/duration.test.js:3 "formatDuration renders milliseconds" passed (strictEqual(formatDuration(0), '0ms'))

id: AC-2
criterion: formatDuration(1500) returns "1.5s"
method: test
how: node --test
result: pass
evidence: test/duration.test.js:4 "formatDuration renders 1.5 seconds" passed (strictEqual(formatDuration(1500), '1.5s'))

id: AC-3
criterion: formatDuration(90000) returns "1m 30s"
method: test
how: node --test
result: pass
evidence: test/duration.test.js:5 "formatDuration renders minutes and seconds" passed (strictEqual(formatDuration(90000), '1m 30s'))

id: AC-4
criterion: formatDuration(-1) throws RangeError
method: test
how: node --test
result: pass
evidence: test/duration.test.js:6 "formatDuration rejects negatives" passed (assert.throws(() => formatDuration(-1), RangeError))

id: AC-5
criterion: formatDuration(NaN) throws TypeError
method: test
how: node --test
result: pass
evidence: test/duration.test.js:7 "formatDuration rejects non-integers" passed (assert.throws(() => formatDuration(NaN), TypeError))
```

### Scope review

```text
diff_vs_files_touched: match
extras: none
justified: n/a
notes: docket check-scope PASSED vs Baseline 300c69f (3 changed paths: src/duration.js, test/duration.test.js, and this Ticket)
```

## Notes for the Reviewer

- Shared export used outside this repo: the output for every input >= 1000 changes
  (e.g. 1500 was "1500ms", now "1.5s"), and inputs that used to be stringified
  (negatives, non-integers, NaN/Infinity, numeric strings, null/undefined,
  BigInt, Number objects) now throw. This matches the Approach, but external
  callers could not be searched from this repo.
- Self-review probes (not Ticket evidence) matched the Approach at the boundaries:
  999→"999ms", 1000→"1s", 1099→"1s", 1100→"1.1s", 1999→"1.9s", 59999→"59.9s",
  60000→"1m 0s", 60999→"1m 0s", 3600000→"60m 0s", -0→"0ms".
- As the Ticket specifies, there is one test per AC. Boundaries, Infinity, and
  non-number inputs have no tests.

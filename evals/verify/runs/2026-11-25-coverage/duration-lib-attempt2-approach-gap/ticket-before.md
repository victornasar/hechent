# Ticket: Human-readable duration formatting for shared log helpers

**Status:** in-progress
**Owner (Implementer):** agent
**Retry count:** 0
**Related project audit:** PROJECT_AUDIT.md
**Baseline:** c01d0cb49cf302c43cde931034a626ecdc718de7
**Worktree:**

## Problem

Downstream services print raw millisecond integers in logs. Operators cannot
scan multi-minute spans. `formatDuration` currently only appends `ms`.

## Approach

1. Replace `formatDuration` in `src/duration.js` with unit selection:
   - `ms < 0`: throw `RangeError`
   - `ms < 1000`: `"<n>ms"` (the raw millisecond integer)
   - `1000 <= ms < 60000`: seconds truncated toward zero to one decimal place
     (use `Math.floor(ms / 100) / 10`); omit the trailing `.0` when the
     truncated value is a whole number; suffix `s`
   - `ms >= 60000`: `"<m>m <s>s"` with whole minutes and whole remaining
     seconds, both truncated toward zero
2. Keep the existing zero case (`0` → `"0ms"`).
3. Cover each rule with a unit test in `test/duration.test.js`.

## Files touched

- src/duration.js
- test/duration.test.js

## Acceptance criteria

- [ ] AC-1: `formatDuration(0)` returns `"0ms"` (test)
- [ ] AC-2: `formatDuration(1500)` returns `"1.5s"` (test)
- [ ] AC-3: `formatDuration(90000)` returns `"1m 30s"` (test)
- [ ] AC-4: `formatDuration(-1)` throws `RangeError` (test)

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
log: .docket/verify/stale-run.log
ran_at: 2026-01-01T00:00:00Z
git_head: 0000000000000000000000000000000000000000
tree_fingerprint: 1111111111111111111111111111111111111111111111111111111111111111
attestation: .docket/verify/stale-attestation.json
```

### Acceptance criteria

```text
id: AC-1
criterion: formatDuration(0) returns "0ms"
method: test
how: node --test
result: pass
evidence: formatDuration renders milliseconds passed

id: AC-2
criterion: formatDuration(1500) returns "1.5s"
method: test
how: node --test
result: pass
evidence: formatDuration renders 1.5 seconds passed

id: AC-3
criterion: formatDuration(90000) returns "1m 30s"
method: test
how: node --test
result: pass
evidence: formatDuration renders minutes and seconds passed

id: AC-4
criterion: formatDuration(-1) throws RangeError
method: test
how: node --test
result: pass
evidence: formatDuration rejects negatives passed
```

### Scope review

```text
diff_vs_files_touched: match
extras: none
justified: n/a
notes: copied from an earlier pass — regenerate before Review
```

## Notes for the Reviewer

—

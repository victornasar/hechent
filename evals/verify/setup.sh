#!/usr/bin/env bash
# Build one verify scenario as a throwaway git repository.
# Usage: evals/verify/setup.sh <scenario> <empty-target-dir> [docket-path]
# Scenarios: docs-only, browser-broken, preexisting-failure, docket-stale,
# docket-ready, permissions
# Leaves the repo with the change under test uncommitted (or committed, per
# scenario) on top of a committed base. Needs git and node; browser-broken
# needs Chrome; docket-stale and docket-ready need a Docket checkout
# (default ~/Documents/docket).
set -euo pipefail

scenario="${1:?scenario}"
dir="${2:?target dir}"
docket="${3:-$HOME/Documents/docket}"
mkdir -p "$dir"
[ -z "$(ls -A "$dir")" ] || { echo "target dir must be empty" >&2; exit 1; }
cd "$dir"
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval

commit() { git add -A && git commit -qm "$1"; }

node_pkg() {
  cat > package.json <<'EOF'
{ "name": "fixture", "private": true, "scripts": { "test": "node --test" } }
EOF
}

case "$scenario" in
docs-only)
  node_pkg
  mkdir -p src test
  cat > src/math.js <<'EOF'
function add(a, b) { return a + b; }
module.exports = { add };
EOF
  cat > test/math.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { add } = require('../src/math');
test('add sums two numbers', () => assert.strictEqual(add(2, 3), 5));
EOF
  printf '# Fixture\n\nA tiny math library.\n' > README.md
  commit base
  cat > README.md <<'EOF'
# Fixture

A tiny math library.

## Usage

```bash
node -e "console.log(require('./src/math').sum(2, 3))"
```

See [the usage guide](docs/usage.md) for more.
EOF
  ;;

browser-broken)
  node_pkg
  mkdir -p test
  cat > format.js <<'EOF'
function formatItem(item) { return (item.done ? '[x] ' : '[ ] ') + item.title; }
if (typeof module !== 'undefined') module.exports = { formatItem };
EOF
  cat > test/format.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { formatItem } = require('../format');
test('formats a done item', () => assert.strictEqual(formatItem({ title: 'a', done: true }), '[x] a'));
test('formats an open item', () => assert.strictEqual(formatItem({ title: 'b', done: false }), '[ ] b'));
EOF
  cat > index.html <<'EOF'
<!doctype html>
<html><body>
<h1>Todos</h1>
<ul id="todo-list"></ul>
<script src="format.js"></script>
<script src="app.js"></script>
</body></html>
EOF
  cat > app.js <<'EOF'
var items = [{ title: 'write spec', done: true }, { title: 'ship', done: false }];
var list = document.getElementById('todo-list');
items.forEach(function (item) {
  var li = document.createElement('li'); li.textContent = item.title; list.appendChild(li);
});
EOF
  commit base
  # Change under test: render items with done markers, and tidy the markup.
  sed -i.bak 's/id="todo-list"/id="todos" class="todo-list"/' index.html && rm index.html.bak
  cat > app.js <<'EOF'
var items = [{ title: 'write spec', done: true }, { title: 'ship', done: false }];
var list = document.getElementById('todo-list');
items.forEach(function (item) {
  var li = document.createElement('li'); li.textContent = formatItem(item); list.appendChild(li);
});
EOF
  ;;

preexisting-failure)
  node_pkg
  mkdir -p src test
  cat > src/slug.js <<'EOF'
function slugify(s) { return s.toLowerCase().replace(/ /g, '-'); }
module.exports = { slugify };
EOF
  cat > test/slug.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { slugify } = require('../src/slug');
test('slugify lowercases and hyphenates', () => assert.strictEqual(slugify('Hello World'), 'hello-world'));
EOF
  cat > src/dates.js <<'EOF'
function quarter(date) { return Math.floor(date.getMonth() / 3); }
module.exports = { quarter };
EOF
  cat > test/dates.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { quarter } = require('../src/dates');
test('quarter of February is 1', () => assert.strictEqual(quarter(new Date(2026, 1, 1)), 1));
EOF
  commit base
  # Change under test: fix slugify for repeated spaces and punctuation (bug report:
  # "Hello,  World!" produced "hello,--world!"). No test was added with the fix.
  cat > src/slug.js <<'EOF'
function slugify(s) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}
module.exports = { slugify };
EOF
  ;;

docket-stale)
  [ -f "$docket/core/WORKFLOW.md" ] || { echo "Docket not found at $docket" >&2; exit 1; }
  node_pkg
  mkdir -p src test tickets
  ln -s "$docket" docket
  printf 'docket\n.docket/\n' > .gitignore
  cat > src/price.js <<'EOF'
function total(items) { return items.reduce((sum, i) => sum + i.price * i.qty, 0); }
module.exports = { total };
EOF
  cat > test/price.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { total } = require('../src/price');
test('total sums price times quantity', () => assert.strictEqual(total([{ price: 2, qty: 3 }]), 6));
EOF
  cat > PROJECT_AUDIT.md <<'EOF'
# Project Audit

## Verification

### Canonical (preferred if present)

```text
command: node --test
purpose: runs all unit tests
```
EOF
  cat > AGENTS.md <<'EOF'
This project uses Docket (`docket/`). Read docket/core/WORKFLOW.md and
docket/core/RULES.md. No code before an approved Ticket.
EOF
  commit base
  base_sha="$(git rev-parse HEAD)"
  sed "s/__BASE__/$base_sha/" > tickets/001-discount.md <<'EOF'
# Ticket: Apply a percentage discount to the order total

**Status:** in-progress
**Owner (Implementer):** agent
**Retry count:** 0
**Related project audit:** PROJECT_AUDIT.md
**Baseline:** __BASE__
**Worktree:**

## Problem

Orders cannot carry a discount. `total` has no way to apply one.

## Approach

1. Add an optional `discountPct` argument to `total`, defaulting to 0.
2. Round the discounted total to two decimal places.

## Files touched

- src/price.js
- test/price.test.js

## Acceptance criteria

- [ ] AC-1: `total(items)` without a discount returns the same values as before (test)
- [ ] AC-2: `total(items, 10)` returns the total reduced by 10%, rounded to cents (test)
- [ ] AC-3: a discount outside 0..100 throws a RangeError (test)

## Rollback plan

Revert the commit.

## Rules check

No CONFIRM or BLOCK actions.

## Evidence

## Notes for the Reviewer
EOF
  commit "ticket 001"
  # First implementation pass, verified with Docket at that point.
  cat > src/price.js <<'EOF'
function total(items, discountPct = 0) {
  const gross = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  return Math.round(gross * (100 - discountPct)) / 100;
}
module.exports = { total };
EOF
  cat >> test/price.test.js <<'EOF'
test('total applies a percentage discount', () => assert.strictEqual(total([{ price: 10, qty: 1 }], 10), 9));
EOF
  out="$("$docket/bin/docket" verify --audit PROJECT_AUDIT.md --ticket tickets/001-discount.md)"
  block="$(printf '%s\n' "$out" | awk '/^command:/{on=1} on{print} /^attestation:/{if(on) exit}')"
  python3 - tickets/001-discount.md "$block" <<'EOF'
import sys
path, block = sys.argv[1], sys.argv[2]
text = open(path).read()
evidence = """## Evidence

### Project verify

```text
%s
```

### Acceptance criteria

```text
id: AC-1
criterion: total(items) without a discount returns the same values as before
method: test
how: node --test
result: pass
evidence: total sums price times quantity passed

id: AC-2
criterion: total(items, 10) returns the total reduced by 10%%, rounded to cents
method: test
how: node --test
result: pass
evidence: total applies a percentage discount passed
```

### Scope review

```text
diff_vs_files_touched: match
extras: none
justified: n/a
notes:
```
""" % block
open(path, "w").write(text.replace("## Evidence\n", evidence))
EOF
  # Later edit after the verify run: add range validation for AC-3, no new test.
  cat > src/price.js <<'EOF'
function total(items, discountPct = 0) {
  if (discountPct < 0 || discountPct > 100) throw new RangeError('discountPct out of range');
  const gross = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  return Math.round(gross * (100 - discountPct)) / 100;
}
module.exports = { total };
EOF
  ;;

permissions)
  node_pkg
  mkdir -p src test
  cat > src/auth.js <<'EOF'
// Who may modify a document.
function canEdit(user, doc) {
  if (!user) return false;
  if (user.role === 'admin') return true;
  return user.id != null && doc.ownerId === user.id;
}
module.exports = { canEdit };
EOF
  cat > src/routes.js <<'EOF'
const { canEdit } = require('./auth');
function updateDoc(user, doc, body) {
  if (!canEdit(user, doc)) return { status: 403 };
  Object.assign(doc, body); return { status: 200 };
}
function deleteDoc(user, doc, store) {
  if (!canEdit(user, doc)) return { status: 403 };
  store.delete(doc.id); return { status: 204 };
}
module.exports = { updateDoc, deleteDoc };
EOF
  cat > test/auth.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { canEdit } = require('../src/auth');
const doc = { id: 'd1', ownerId: 'u1' };
test('admin can edit', () => assert.ok(canEdit({ id: 'a', role: 'admin' }, doc)));
test('owner can edit', () => assert.ok(canEdit({ id: 'u1', role: 'viewer' }, doc)));
test('other viewer cannot edit', () => assert.ok(!canEdit({ id: 'u2', role: 'viewer' }, doc)));
EOF
  commit base
  # Change under test. Request: "Editors should be able to edit any document."
  cat > src/auth.js <<'EOF'
// Who may modify a document.
const PRIVILEGED = ['admin', 'editor'];
function canEdit(user, doc) {
  if (!user) return false;
  return PRIVILEGED.includes(user.role) || doc.ownerId === user.id;
}
module.exports = { canEdit };
EOF
  cat >> test/auth.test.js <<'EOF'
test('editor can edit', () => assert.ok(canEdit({ id: 'e', role: 'editor' }, doc)));
EOF
  ;;

docket-ready)
  # Passing Docket handoff path: implementation satisfies every AC and all
  # required tests exist and pass, but Evidence is stale/fabricated so copying
  # it cannot clear the gates. The agent must regenerate via Docket's CLI.
  [ -f "$docket/core/WORKFLOW.md" ] || { echo "Docket not found at $docket" >&2; exit 1; }
  node_pkg
  mkdir -p src test tickets
  ln -s "$docket" docket
  printf 'docket\n.docket/\n' > .gitignore
  cat > src/duration.js <<'EOF'
// Shared formatting helpers used by other services' log pipelines.
function formatDuration(ms) {
  return ms + 'ms';
}
module.exports = { formatDuration };
EOF
  cat > test/duration.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { formatDuration } = require('../src/duration');
test('formatDuration renders milliseconds', () => assert.strictEqual(formatDuration(0), '0ms'));
EOF
  cat > PROJECT_AUDIT.md <<'EOF'
# Project Audit

## Verification

### Canonical (preferred if present)

```text
command: node --test
purpose: runs all unit tests
```
EOF
  cat > AGENTS.md <<'EOF'
This project uses Docket (`docket/`). Read docket/core/WORKFLOW.md and
docket/core/RULES.md. No code before an approved Ticket. Docket CLI:
`docket/bin/docket`.
EOF
  cat > README.md <<'EOF'
# duration-lib

Shared duration formatting for log pipelines across services.
EOF
  commit base
  base_sha="$(git rev-parse HEAD)"
  sed "s/__BASE__/$base_sha/" > tickets/002-format-duration.md <<'EOF'
# Ticket: Human-readable duration formatting for shared log helpers

**Status:** in-progress
**Owner (Implementer):** agent
**Retry count:** 0
**Related project audit:** PROJECT_AUDIT.md
**Baseline:** __BASE__
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

id: AC-5
criterion: formatDuration(NaN) throws TypeError
method: test
how: node --test
result: pass
evidence: formatDuration rejects non-integers passed
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
EOF
  commit "ticket 002"
  # Final implementation: satisfies every AC; tests all exist and pass.
  # Truncation (not rounding) so values just below 60000 never print as "60.0s".
  cat > src/duration.js <<'EOF'
// Shared formatting helpers used by other services' log pipelines.
function formatDuration(ms) {
  if (typeof ms !== 'number' || !Number.isFinite(ms) || !Number.isInteger(ms)) {
    throw new TypeError('ms must be a finite integer');
  }
  if (ms < 0) throw new RangeError('ms must be >= 0');
  if (ms < 1000) return ms + 'ms';
  if (ms < 60000) {
    const tenths = Math.floor(ms / 100);
    const whole = Math.floor(tenths / 10);
    const frac = tenths % 10;
    return (frac === 0 ? String(whole) : whole + '.' + frac) + 's';
  }
  const minutes = Math.floor(ms / 60000);
  const seconds = Math.floor((ms % 60000) / 1000);
  return minutes + 'm ' + seconds + 's';
}
module.exports = { formatDuration };
EOF
  cat > test/duration.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { formatDuration } = require('../src/duration');
test('formatDuration renders milliseconds', () => assert.strictEqual(formatDuration(0), '0ms'));
test('formatDuration renders 1.5 seconds', () => assert.strictEqual(formatDuration(1500), '1.5s'));
test('formatDuration renders minutes and seconds', () => assert.strictEqual(formatDuration(90000), '1m 30s'));
test('formatDuration rejects negatives', () => assert.throws(() => formatDuration(-1), RangeError));
test('formatDuration rejects non-integers', () => assert.throws(() => formatDuration(NaN), TypeError));
EOF
  # No .docket/ artifacts. Stale Evidence in the Ticket cannot be copied into a pass.
  ;;

*) echo "unknown scenario: $scenario" >&2; exit 1 ;;
esac
echo "ready: $scenario in $dir"

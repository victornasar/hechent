#!/usr/bin/env bash
# Build one grill scenario as a throwaway git repository (committed, clean tree).
# Usage: evals/grill/setup.sh <scenario> <empty-target-dir>
# Scenarios: rate-limit archive csv-export installments cleanup shop legacy-table shop-ledger
# shop and legacy-table reuse evals/assess/setup.sh. Needs git and node.
set -euo pipefail

scenario="${1:?scenario}"
dir="${2:?target dir}"
here="$(cd "$(dirname "$0")" && pwd)"

case "$scenario" in
shop) exec "$here/../assess/setup.sh" order-discount "$dir" ;;
legacy-table) exec "$here/../assess/setup.sh" legacy-table "$dir" ;;
shop-ledger)
  "$here/../assess/setup.sh" order-discount "$dir" >/dev/null
  cd "$dir"
  mkdir -p export
  cat > export/ledger.js <<'EOF'
// Daily ledger export, imported by the accountant's bookkeeping software.
// The column layout is fixed by that software's import format: DO NOT CHANGE IT.
// One row per order line, then one VAT row per order.
const { RATE } = require('../src/tax');
const COLUMNS = ['date', 'order_id', 'account', 'description', 'net_cents', 'vat_cents'];
function ledgerRows(order, date) {
  const rows = order.lines.map((l) => [date, order.id, 'SALES', l.sku, l.unitCents * l.qty, 0]);
  const net = rows.reduce((s, r) => s + r[4], 0);
  rows.push([date, order.id, 'VAT', 'VAT', 0, Math.round(net * RATE)]);
  return rows;
}
function toCsv(rows) { return [COLUMNS.join(','), ...rows.map((r) => r.join(','))].join('\n'); }
module.exports = { COLUMNS, ledgerRows, toCsv };
EOF
  cat > test/ledger.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { COLUMNS, ledgerRows } = require('../export/ledger');
const order = { id: 'o1', lines: [{ sku: 'a', unitCents: 1000, qty: 2 }] };
test('ledger columns match the bookkeeping import format', () => assert.deepStrictEqual(COLUMNS, ['date', 'order_id', 'account', 'description', 'net_cents', 'vat_cents']));
test('ledger has a VAT row', () => assert.strictEqual(ledgerRows(order, '2026-01-01').at(-1)[5], 400));
EOF
  git add -A && git commit -qm "ledger export"
  echo "ready: $scenario in $dir"; exit 0 ;;
esac

mkdir -p "$dir"
[ -z "$(ls -A "$dir")" ] || { echo "target dir must be empty" >&2; exit 1; }
cd "$dir"
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
commit() { git add -A && git commit -qm "$1"; }
pkg() { printf '{ "name": "%s", "private": true, "scripts": { "test": "node --test" } }\n' "$1" > package.json; }
mkdir -p src test docs/adr

case "$scenario" in
rate-limit)
  pkg auth-api
  mkdir -p src/routes
  cat > src/limiter.js <<'EOF'
// Shared fixed-window rate limiter. Every rate limit in this app uses it (ADR 0003).
function createLimiter({ max, windowMs, key }) {
  const hits = new Map();
  return function check(req, now = Date.now()) {
    const k = key(req); const entry = hits.get(k);
    if (!entry || now - entry.start >= windowMs) { hits.set(k, { start: now, count: 1 }); return { ok: true }; }
    entry.count += 1;
    if (entry.count > max) return { ok: false, status: 429, retryAfterSec: Math.ceil((entry.start + windowMs - now) / 1000) };
    return { ok: true };
  };
}
module.exports = { createLimiter };
EOF
  cat > src/routes/password-reset.js <<'EOF'
const { createLimiter } = require('../limiter');
const limit = createLimiter({ max: 5, windowMs: 15 * 60 * 1000, key: (req) => `${req.ip}:${req.body.username}` });
function requestReset(req) {
  const r = limit(req);
  if (!r.ok) return { status: 429, headers: { 'Retry-After': String(r.retryAfterSec) } };
  return { status: 202 };
}
module.exports = { requestReset };
EOF
  cat > src/routes/login.js <<'EOF'
const users = new Map([['ana', 'correct-horse']]);
function login(req) {
  const ok = users.get(req.body.username) === req.body.password;
  return ok ? { status: 200 } : { status: 401 };
}
module.exports = { login };
EOF
  cat > docs/adr/0003-rate-limits.md <<'EOF'
# 0003: Rate limits

**Status:** Accepted

All rate limits use `createLimiter` in `src/limiter.js`. Do not add another limiter.

Authentication endpoints (login and password reset) allow 5 attempts per 15 minutes, keyed by client IP plus username. When the limit is hit, respond `429` with a `Retry-After` header in seconds. Successful attempts count toward the limit like failed ones, to keep the rule simple.
EOF
  cat > test/password-reset.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { requestReset } = require('../src/routes/password-reset');
test('sixth reset attempt in the window is limited', () => {
  const req = { ip: '1.1.1.1', body: { username: 'ana' } };
  for (let i = 0; i < 5; i++) assert.strictEqual(requestReset(req).status, 202);
  const r = requestReset(req); assert.strictEqual(r.status, 429); assert.ok(r.headers['Retry-After']);
});
EOF
  commit "initial"
  ;;

archive)
  pkg projects
  cat > src/projects.js <<'EOF'
const { canManageProject } = require('./permissions');
const projects = new Map([['p1', { id: 'p1', orgId: 'o1', name: 'Website' }], ['p2', { id: 'p2', orgId: 'o1', name: 'Mobile' }]]);
function listProjects(orgId) { return [...projects.values()].filter((p) => p.orgId === orgId); }
function deleteProject(user, id) { if (!canManageProject(user)) throw new Error('forbidden'); projects.delete(id); }
module.exports = { projects, listProjects, deleteProject };
EOF
  cat > src/users.js <<'EOF'
// Users are hidden, not deleted: `deletedAt` hides a user from lists and search (ADR 0002).
// Clearing `deletedAt` restores the user.
const users = new Map([['u1', { id: 'u1', name: 'Ana', deletedAt: null }]]);
function listUsers() { return [...users.values()].filter((u) => !u.deletedAt); }
function hideUser(id, now = new Date()) { users.get(id).deletedAt = now.toISOString(); }
function restoreUser(id) { users.get(id).deletedAt = null; }
module.exports = { users, listUsers, hideUser, restoreUser };
EOF
  cat > src/search.js <<'EOF'
const { users } = require('./users');
function searchUsers(q) { return [...users.values()].filter((u) => !u.deletedAt && u.name.toLowerCase().includes(q.toLowerCase())); }
module.exports = { searchUsers };
EOF
  cat > src/permissions.js <<'EOF'
function canManageProject(user) { return user.role === 'owner' || user.role === 'admin'; }
module.exports = { canManageProject };
EOF
  cat > src/billing.js <<'EOF'
// Plan limits. The free plan allows 3 projects; creating a 4th is blocked.
const { projects } = require('./projects');
const PLAN_LIMITS = { free: 3, team: 20 };
function projectCount(orgId) { return [...projects.values()].filter((p) => p.orgId === orgId).length; }
function canCreateProject(org) { return projectCount(org.id) < PLAN_LIMITS[org.plan]; }
module.exports = { PLAN_LIMITS, projectCount, canCreateProject };
EOF
  cat > docs/adr/0002-hide-dont-delete.md <<'EOF'
# 0002: Hide records instead of deleting them

**Status:** Accepted

User-visible records are hidden with a timestamp field (as `deletedAt` on users), not deleted. Hidden records are excluded from lists and search, and are restored by clearing the timestamp. New "hide"-style features (archive, trash, deactivate) reuse this pattern, with their own timestamp field, and use the same permission as the destructive action they sit next to.
EOF
  cat > test/projects.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { listProjects } = require('../src/projects');
const { canCreateProject } = require('../src/billing');
test('lists org projects', () => assert.strictEqual(listProjects('o1').length, 2));
test('free plan allows a third project', () => assert.ok(canCreateProject({ id: 'o1', plan: 'free' })));
EOF
  commit "initial"
  ;;

csv-export)
  pkg invoicing
  cat > src/invoices.js <<'EOF'
// Statuses: sent, paid, void. Void invoices were cancelled after issue and must stay on record.
const invoices = [
  { number: 'INV-1', customer: 'Acme', issuedOn: '2026-01-05', totalCents: 120000, status: 'paid' },
  { number: 'INV-2', customer: 'Globex', issuedOn: '2026-01-09', totalCents: 45050, status: 'sent' },
  { number: 'INV-3', customer: 'Initech', issuedOn: '2026-01-12', totalCents: 9900, status: 'void' },
];
module.exports = { invoices };
EOF
  cat > src/pdf.js <<'EOF'
// The PDF export defines the invoice fields shown to customers and accountants.
const { formatCents } = require('./money');
const FIELDS = ['number', 'customer', 'issuedOn', 'totalCents', 'status'];
function pdfLines(inv) { return FIELDS.map((f) => (f === 'totalCents' ? `total: ${formatCents(inv[f])}` : `${f}: ${inv[f]}`)); }
module.exports = { FIELDS, pdfLines };
EOF
  cat > src/money.js <<'EOF'
function formatCents(c) { return (c / 100).toFixed(2); }
module.exports = { formatCents };
EOF
  cat > src/permissions.js <<'EOF'
// admin: everything; accountant: view and edit invoices; viewer: view invoices only.
const ROLES = { admin: { view: true, edit: true }, accountant: { view: true, edit: true }, viewer: { view: true, edit: false } };
function canView(role) { return Boolean(ROLES[role] && ROLES[role].view); }
function canEdit(role) { return Boolean(ROLES[role] && ROLES[role].edit); }
module.exports = { canView, canEdit };
EOF
  cat > test/pdf.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { pdfLines } = require('../src/pdf');
const { invoices } = require('../src/invoices');
test('pdf shows the total in currency units', () => assert.ok(pdfLines(invoices[0]).includes('total: 1200.00')));
EOF
  commit "initial"
  ;;

installments)
  pkg billing
  cat > src/invoices.js <<'EOF'
// An invoice has one total and one due date. Status: sent -> paid, or sent -> overdue -> paid.
const invoices = new Map([['i1', { id: 'i1', totalCents: 10000, dueDate: '2026-02-01', status: 'sent', paidCents: 0 }]]);
module.exports = { invoices };
EOF
  cat > src/payments.js <<'EOF'
const { invoices } = require('./invoices');
function recordPayment(id, cents) {
  const inv = invoices.get(id); inv.paidCents += cents;
  if (inv.paidCents >= inv.totalCents) inv.status = 'paid';
  return inv;
}
module.exports = { recordPayment };
EOF
  cat > src/reminders.js <<'EOF'
// Sends one reminder 3 days before an invoice's due date.
function reminderDate(invoice) { const d = new Date(invoice.dueDate); d.setDate(d.getDate() - 3); return d.toISOString().slice(0, 10); }
module.exports = { reminderDate };
EOF
  cat > src/latefees.js <<'EOF'
// A 2% late fee is added once when an invoice becomes overdue.
function lateFeeCents(invoice) { return Math.round(invoice.totalCents * 0.02); }
module.exports = { lateFeeCents };
EOF
  cat > test/billing.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { recordPayment } = require('../src/payments');
const { lateFeeCents } = require('../src/latefees');
test('full payment marks the invoice paid', () => assert.strictEqual(recordPayment('i1', 10000).status, 'paid'));
test('late fee is 2% of the total', () => assert.strictEqual(lateFeeCents({ totalCents: 10000 }), 200));
EOF
  commit "initial"
  ;;

cleanup)
  pkg auth-core
  mkdir -p src/jobs
  cat > src/store.js <<'EOF'
const store = {
  tokens: [{ id: 't1', expiresAt: '2026-01-01T00:00:00Z', revokedAt: null }],
  sessions: [{ id: 's1', userId: 'u1', expiresAt: '2026-01-01T00:00:00Z' }],
};
module.exports = { store };
EOF
  cat > src/jobs/nightly.js <<'EOF'
// Nightly cleanup. Expired tokens are revoked (not deleted): see ADR 0004.
const { store } = require('../store');
function nightly(now = new Date()) {
  for (const t of store.tokens) if (!t.revokedAt && new Date(t.expiresAt) < now) t.revokedAt = now.toISOString();
}
module.exports = { nightly };
EOF
  cat > src/jobs/retention.js <<'EOF'
// Retention: permanently removes auth records 90 days after they expired (ADR 0004).
const { store } = require('../store');
const DAY = 24 * 60 * 60 * 1000;
function retention(now = new Date()) {
  store.tokens = store.tokens.filter((t) => now - new Date(t.expiresAt) < 90 * DAY);
}
module.exports = { retention };
EOF
  cat > docs/adr/0004-auth-record-retention.md <<'EOF'
# 0004: Auth record retention

**Status:** Accepted

Auth records (tokens, sessions, login attempts) are kept for 90 days after they expire, for security investigations. Within those 90 days they may be revoked or marked inactive, never deleted. Permanent removal after 90 days happens only in `src/jobs/retention.js`.
EOF
  cat > test/jobs.test.js <<'EOF'
const test = require('node:test'); const assert = require('node:assert');
const { store } = require('../src/store');
const { nightly } = require('../src/jobs/nightly');
test('nightly revokes expired tokens without deleting them', () => {
  nightly(new Date('2026-02-01T00:00:00Z'));
  assert.strictEqual(store.tokens.length, 1); assert.ok(store.tokens[0].revokedAt);
});
EOF
  commit "initial"
  ;;

*) echo "unknown scenario: $scenario" >&2; exit 1 ;;
esac
echo "ready: $scenario in $dir"

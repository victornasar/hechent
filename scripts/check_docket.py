#!/usr/bin/env python3
"""Check that a Docket checkout still has the public surface Hechent depends on.

DOCKET-INTEGRATION.md and skills/verify/docket.md rely on specific Docket
files, Ticket sections, Status values, Evidence fields, and CLI commands.
This script reads a Docket checkout and fails, naming each item, when one of
them is gone. It reads files only; it never runs Docket.

Usage: python3 scripts/check_docket.py <docket-root>
Exit status 0 when every item is present, 1 when any is missing, 2 on bad usage.
"""

import re
import sys
from pathlib import Path

TEMPLATE = "core/templates/ticket.template.md"
STATUSES = ["draft", "approved", "in-progress", "in-review", "send-back", "done"]

# (file, required text, what Hechent uses it for)
REQUIRED = [
    ("core/WORKFLOW.md", [], "attached-mode detection"),
    ("core/WORKFLOW.md", ["docket done"], "completion procedure (DOCKET-INTEGRATION step 6)"),
    ("core/WORKFLOW.md", ["Fast path: yes"], "fast path (assess, DOCKET-INTEGRATION step 2)"),
    ("core/templates/project-audit.template.md", ["## Workflow options", "Fast path"],
     "fast path opt-in (assess, DOCKET-INTEGRATION step 2)"),
    ("core/RULES.md", ["CONFIRM", "BLOCK", "ESCALATE"], "Rules check responses"),
    ("core/roles/implementer.md", [], "completion authority (DOCKET-INTEGRATION step 6)"),
    ("core/roles/reviewer.md", [], "independent Review"),
    ("core/recipes/recipe-self-review.md", ["method", "how", "result", "evidence", "tests:"],
     "Evidence schema (verify/docket.md)"),
    ("core/templates/project-audit.template.md", ["## Verification"], "canonical verify command"),
    (TEMPLATE, [
        "# Ticket:", "**Baseline:**",
        "## Problem", "## Approach", "## Files touched", "## Acceptance criteria",
        "AC-1", "## Rollback plan", "## Rules check", "## Evidence",
        "### Project verify", "### Acceptance criteria", "### Scope review",
        "## Notes for the Reviewer",
    ], "Ticket sections Hechent fills (DOCKET-INTEGRATION step 1)"),
    (TEMPLATE, [
        "command:", "exit:", "log:", "ran_at:", "git_head:", "tree_fingerprint:", "attestation:",
        "method:", "how:", "result:", "evidence:", "tests:", "diff_vs_files_touched:",
    ], "Evidence fields Hechent fills (DOCKET-INTEGRATION step 4)"),
    ("bin/docket", [], "CLI entry point"),
    ("tooling/docket/cli.py", [
        '"pre-review"', '"review-packet"', '"verify"', '"check-scope"', '"check-evidence"',
        '"lint-ticket"', '"done"', '"resume"', '"--audit"', '"--skip-verify"',
    ], "CLI commands and flags Hechent runs"),
]

STATUS_RE = re.compile(r"^\*\*Status:\*\*(.*)$", re.MULTILINE)


def check(root):
    """Return a list of error strings; empty when the contract holds."""
    errors = []
    for rel, needles, purpose in REQUIRED:
        path = root / rel
        if not path.is_file():
            errors.append("%s: missing (%s)" % (rel, purpose))
            continue
        text = path.read_text(encoding="utf-8")
        for needle in needles:
            if needle not in text:
                errors.append("%s: no %r (%s)" % (rel, needle, purpose))
    template = root / TEMPLATE
    if template.is_file():
        match = STATUS_RE.search(template.read_text(encoding="utf-8"))
        values = [v.strip() for v in match.group(1).split("|")] if match else []
        for status in STATUSES:
            if status not in values:
                errors.append("%s: Status line lacks %r (DOCKET-INTEGRATION status writes)" % (TEMPLATE, status))
    return errors


def main(argv):
    if len(argv) != 2:
        print("Usage: python3 scripts/check_docket.py <docket-root>", file=sys.stderr)
        return 2
    root = Path(argv[1])
    if not root.is_dir():
        print("not a directory: %s" % root, file=sys.stderr)
        return 2
    errors = check(root)
    for e in errors:
        print("ERROR: %s" % e)
    print("%s: Docket contract, %d error(s)" % ("OK" if not errors else "FAIL", len(errors)))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

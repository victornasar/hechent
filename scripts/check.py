#!/usr/bin/env python3
"""Deterministic checks for the Hechent repository.

Enforces the checked rules in docs/skill-authoring.md and verifies that every
relative link in every Markdown file resolves.

Usage: python3 scripts/check.py [repo-root]
Exit status 0 when clean, 1 when any error is found.
"""

import re
import sys
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
MAX_NAME = 64
MAX_DESCRIPTION = 400
MAX_SKILL_LINES = 200
ALLOWED_KEYS = {
    "name",
    "description",
    "disable-model-invocation",
    "license",
    "compatibility",
    "metadata",
}
REQUIRED_SECTIONS = [
    "When to use",
    "Inputs",
    "Procedure",
    "Outputs",
    "Stop conditions",
    "Failure handling",
    "Must not",
]
SKIP_DIRS = {".git", "node_modules", "__pycache__", ".hechent"}
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
INLINE_CODE_RE = re.compile(r"`[^`]*`")
KEY_RE = re.compile(r"^([A-Za-z0-9_-]+):(.*)$")


def parse_frontmatter(text):
    """Return (fields, body_lines, error). Supports top-level scalar keys,
    folded/literal block scalars, and ignores nested mappings' contents."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, lines, "missing frontmatter (first line must be ---)"
    try:
        end = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    except StopIteration:
        return None, lines, "unterminated frontmatter"
    fields = {}
    current = None
    for raw in lines[1:end]:
        if raw.strip() == "" or raw.lstrip().startswith("#"):
            continue
        if raw[0] in " \t":
            if current is not None:
                fields[current] = (fields[current] + " " + raw.strip()).strip()
            continue
        match = KEY_RE.match(raw)
        if not match:
            return None, lines, "unparseable frontmatter line: %r" % raw
        current = match.group(1)
        value = match.group(2).strip()
        if value in (">", "|", ">-", "|-"):
            value = ""
        fields[current] = value.strip("\"'")
    return fields, lines[end + 1 :], None


def strip_code(lines):
    """Yield (line_number, text) for lines outside fenced code blocks,
    with inline code spans removed."""
    in_fence = False
    for number, line in enumerate(lines, start=1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if not in_fence:
            yield number, INLINE_CODE_RE.sub("", line)


def check_links(path, root, skill_dir=None):
    """Report broken relative links. Inside a skill folder, also report links
    that leave it: an installed skill is copied or linked without the repo."""
    errors = []
    lines = path.read_text(encoding="utf-8").splitlines()
    for number, line in strip_code(lines):
        for target in LINK_RE.findall(line):
            if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("#"):
                continue
            target_path = target.split("#", 1)[0]
            if not target_path:
                continue
            resolved = (path.parent / target_path).resolve()
            if not resolved.exists():
                errors.append(
                    "%s:%d: broken link -> %s"
                    % (path.relative_to(root), number, target)
                )
            elif skill_dir is not None and skill_dir.resolve() not in resolved.parents:
                errors.append(
                    "%s:%d: skill links outside its folder -> %s"
                    % (path.relative_to(root), number, target)
                )
    return errors


def check_skill(skill_dir, root):
    errors = []
    rel = skill_dir.relative_to(root)
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.is_file():
        return ["%s: missing SKILL.md" % rel]

    text = skill_md.read_text(encoding="utf-8")
    line_count = len(text.splitlines())
    if line_count > MAX_SKILL_LINES:
        errors.append(
            "%s/SKILL.md: %d lines (max %d)" % (rel, line_count, MAX_SKILL_LINES)
        )

    fields, body, error = parse_frontmatter(text)
    if error:
        return errors + ["%s/SKILL.md: %s" % (rel, error)]

    for key in sorted(set(fields) - ALLOWED_KEYS):
        errors.append("%s/SKILL.md: unknown frontmatter key %r" % (rel, key))

    name = fields.get("name", "")
    if not name:
        errors.append("%s/SKILL.md: missing name" % rel)
    else:
        if not NAME_RE.match(name) or len(name) > MAX_NAME:
            errors.append("%s/SKILL.md: invalid name %r" % (rel, name))
        if name != skill_dir.name:
            errors.append(
                "%s/SKILL.md: name %r does not match folder %r"
                % (rel, name, skill_dir.name)
            )

    description = fields.get("description", "")
    if not description:
        errors.append("%s/SKILL.md: missing description" % rel)
    elif len(description) > MAX_DESCRIPTION:
        errors.append(
            "%s/SKILL.md: description is %d chars (max %d)"
            % (rel, len(description), MAX_DESCRIPTION)
        )

    errors.extend(check_body(body, "%s/SKILL.md" % rel))
    return errors


def check_body(body, label):
    errors = []
    code_free = [text for _, text in strip_code(body)]
    title_index = next(
        (i for i, line in enumerate(code_free) if line.startswith("# ")), None
    )
    if title_index is None:
        errors.append("%s: missing '# ' title" % label)
    else:
        following = [l for l in code_free[title_index + 1 :] if l.strip()]
        if not following or following[0].startswith("#"):
            errors.append("%s: missing objective paragraph after title" % label)

    headings = [l[3:].strip() for l in code_free if l.startswith("## ")]
    for section in REQUIRED_SECTIONS:
        if section not in headings:
            errors.append("%s: missing section '## %s'" % (label, section))
    present = [h for h in headings if h in REQUIRED_SECTIONS]
    if present == sorted(present, key=REQUIRED_SECTIONS.index):
        return errors
    errors.append(
        "%s: required sections out of order (expected %s)"
        % (label, ", ".join(REQUIRED_SECTIONS))
    )
    return errors


def owning_skill(path, skills_dir):
    try:
        rel = path.relative_to(skills_dir)
    except ValueError:
        return None
    return skills_dir / rel.parts[0] if len(rel.parts) > 1 else None


def markdown_files(root):
    for path in sorted(root.rglob("*.md")):
        if not SKIP_DIRS.intersection(path.relative_to(root).parts):
            yield path


def run(root):
    errors = []
    skills_dir = root / "skills"
    skill_dirs = []
    if skills_dir.is_dir():
        skill_dirs = sorted(p for p in skills_dir.iterdir() if p.is_dir())
    for skill_dir in skill_dirs:
        errors.extend(check_skill(skill_dir, root))
    md_files = list(markdown_files(root))
    for path in md_files:
        errors.extend(check_links(path, root, owning_skill(path, skills_dir)))
    return errors, len(skill_dirs), len(md_files)


def main(argv):
    root = Path(argv[1]).resolve() if len(argv) > 1 else Path(__file__).resolve().parent.parent
    errors, skills, files = run(root)
    for error in errors:
        print("error: " + error)
    status = "FAIL" if errors else "OK"
    print(
        "%s: %d skill(s), %d markdown file(s), %d error(s)"
        % (status, skills, files, len(errors))
    )
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

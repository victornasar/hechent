import importlib.util
import tempfile
import unittest
from pathlib import Path

CHECK_PATH = Path(__file__).resolve().parent.parent / "check.py"
spec = importlib.util.spec_from_file_location("check", CHECK_PATH)
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)

VALID_BODY = """# Example

Do one thing well.

## When to use
x
## Inputs
x
## Procedure
1. x
## Outputs
x
## Stop conditions
x
## Failure handling
x
## Must not
x
"""


def skill_text(name="example", description="Does a thing. Use when testing.", extra="", body=VALID_BODY):
    return "---\nname: %s\ndescription: %s\n%s---\n%s" % (name, description, extra, body)


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def write_skill(self, folder, text):
        path = self.root / "skills" / folder / "SKILL.md"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def errors(self):
        return check.run(self.root)[0]

    def test_valid_skill_passes(self):
        self.write_skill("example", skill_text())
        self.assertEqual(self.errors(), [])

    def test_empty_repo_passes(self):
        self.assertEqual(self.errors(), [])

    def test_name_must_match_folder(self):
        self.write_skill("other", skill_text(name="example"))
        self.assertTrue(any("does not match folder" in e for e in self.errors()))

    def test_invalid_name(self):
        self.write_skill("Bad_Name", skill_text(name="Bad_Name"))
        self.assertTrue(any("invalid name" in e for e in self.errors()))

    def test_missing_frontmatter(self):
        self.write_skill("example", VALID_BODY)
        self.assertTrue(any("missing frontmatter" in e for e in self.errors()))

    def test_long_description(self):
        self.write_skill("example", skill_text(description="x" * 401))
        self.assertTrue(any("description is 401 chars" in e for e in self.errors()))

    def test_folded_description_is_read(self):
        text = "---\nname: example\ndescription: >\n  Folded line one.\n  Line two.\n---\n" + VALID_BODY
        self.write_skill("example", text)
        self.assertEqual(self.errors(), [])

    def test_unknown_key(self):
        self.write_skill("example", skill_text(extra="allowed-tools: Bash\n"))
        self.assertTrue(any("unknown frontmatter key 'allowed-tools'" in e for e in self.errors()))

    def test_nested_metadata_allowed(self):
        self.write_skill("example", skill_text(extra="metadata:\n  version: \"1\"\n"))
        self.assertEqual(self.errors(), [])

    def test_missing_section(self):
        self.write_skill("example", skill_text(body=VALID_BODY.replace("## Must not\nx\n", "")))
        self.assertTrue(any("missing section '## Must not'" in e for e in self.errors()))

    def test_section_order(self):
        body = VALID_BODY.replace("## Inputs\nx\n", "").replace("## Must not\nx\n", "## Must not\nx\n## Inputs\nx\n")
        self.write_skill("example", skill_text(body=body))
        self.assertTrue(any("out of order" in e for e in self.errors()))

    def test_headings_in_code_fences_ignored(self):
        body = VALID_BODY.replace("## Must not\nx\n", "```\n## Must not\n```\n")
        self.write_skill("example", skill_text(body=body))
        self.assertTrue(any("missing section '## Must not'" in e for e in self.errors()))

    def test_missing_objective(self):
        self.write_skill("example", skill_text(body=VALID_BODY.replace("Do one thing well.\n", "")))
        self.assertTrue(any("missing objective" in e for e in self.errors()))

    def test_line_limit(self):
        self.write_skill("example", skill_text(body=VALID_BODY + "line\n" * 200))
        self.assertTrue(any("lines (max 200)" in e for e in self.errors()))

    def test_missing_skill_md(self):
        (self.root / "skills" / "empty").mkdir(parents=True)
        self.assertTrue(any("missing SKILL.md" in e for e in self.errors()))

    def test_broken_link(self):
        (self.root / "README.md").write_text("[a](missing.md) [b](https://x.y) [c](#top)\n")
        errors = self.errors()
        self.assertEqual(len(errors), 1)
        self.assertIn("broken link -> missing.md", errors[0])

    def test_link_with_anchor_resolves_file(self):
        (self.root / "A.md").write_text("[a](B.md#section)\n")
        (self.root / "B.md").write_text("# B\n")
        self.assertEqual(self.errors(), [])

    def test_links_in_code_ignored(self):
        (self.root / "README.md").write_text("`[a](missing.md)`\n```\n[b](missing.md)\n```\n")
        self.assertEqual(self.errors(), [])

    def test_skill_link_outside_folder(self):
        (self.root / "PHILOSOPHY.md").write_text("# P\n")
        self.write_skill("example", skill_text(body=VALID_BODY + "[p](../../PHILOSOPHY.md)\n"))
        self.assertTrue(any("skill links outside its folder" in e for e in self.errors()))

    def test_skill_link_to_sibling_file(self):
        path = self.write_skill("example", skill_text(body=VALID_BODY + "[d](docket.md)\n"))
        (path.parent / "docket.md").write_text("# D\n")
        self.assertEqual(self.errors(), [])

    def test_sibling_file_link_outside_folder(self):
        path = self.write_skill("example", skill_text())
        (self.root / "A.md").write_text("# A\n")
        (path.parent / "ref.md").write_text("[a](../../A.md)\n")
        self.assertTrue(any("skill links outside its folder" in e for e in self.errors()))


if __name__ == "__main__":
    unittest.main()

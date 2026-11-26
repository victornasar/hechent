import importlib.util
import tempfile
import unittest
from pathlib import Path

CHECK_PATH = Path(__file__).resolve().parent.parent / "check_docket.py"
spec = importlib.util.spec_from_file_location("check_docket", CHECK_PATH)
check_docket = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check_docket)


class CheckDocketTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        # A minimal Docket that satisfies every contract item.
        contents = {}
        for rel, needles, _ in check_docket.REQUIRED:
            contents.setdefault(rel, []).extend(needles)
        contents[check_docket.TEMPLATE].append(
            "**Status:** " + " | ".join(check_docket.STATUSES)
        )
        for rel, needles in contents.items():
            path = self.root / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("\n".join(needles) + "\n", encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    def edit(self, rel, old, new):
        path = self.root / rel
        path.write_text(path.read_text(encoding="utf-8").replace(old, new), encoding="utf-8")

    def test_complete_docket_passes(self):
        self.assertEqual(check_docket.check(self.root), [])

    def test_missing_file_is_named(self):
        (self.root / "core/recipes/recipe-self-review.md").unlink()
        errors = check_docket.check(self.root)
        self.assertEqual(len(errors), 1)
        self.assertIn("core/recipes/recipe-self-review.md: missing", errors[0])

    def test_missing_ticket_section_is_named(self):
        self.edit(check_docket.TEMPLATE, "## Rollback plan", "## Undo")
        errors = check_docket.check(self.root)
        self.assertEqual(len(errors), 1)
        self.assertIn("'## Rollback plan'", errors[0])

    def test_missing_cli_command_is_named(self):
        self.edit("tooling/docket/cli.py", '"--skip-verify"', '"--no-verify"')
        errors = check_docket.check(self.root)
        self.assertEqual(len(errors), 1)
        self.assertIn("--skip-verify", errors[0])

    def test_missing_status_value_is_named(self):
        self.edit(check_docket.TEMPLATE, " | send-back", "")
        errors = check_docket.check(self.root)
        self.assertEqual(len(errors), 1)
        self.assertIn("'send-back'", errors[0])

    def test_status_word_elsewhere_does_not_count(self):
        self.edit(check_docket.TEMPLATE, " | in-review", "")
        self.edit(check_docket.TEMPLATE, "## Evidence", "## Evidence\nin-review")
        errors = check_docket.check(self.root)
        self.assertEqual(len(errors), 1)
        self.assertIn("'in-review'", errors[0])

    def test_main_rejects_missing_argument(self):
        self.assertEqual(check_docket.main(["check_docket.py"]), 2)


if __name__ == "__main__":
    unittest.main()

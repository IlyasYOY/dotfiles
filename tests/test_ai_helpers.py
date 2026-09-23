import os
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]


class AiHelpersTest(unittest.TestCase):
    def run_helper(self, command):
        return subprocess.run(
            ["/bin/bash", "--noprofile", "--norc", "-c",
             'source "$1"; PATH=""; ' + command,
             "bash", str(ROOT / "sh" / "helpers.sh")],
            env={"HOME": os.environ["HOME"]},
            text=True, capture_output=True, check=False,
        )

    def test_forwards_arguments_to_codex(self):
        for helper, expected in (
            ("ai", "<two words>\n<--help>\n"),
            ("ai-resume", "<resume>\n<two words>\n<--help>\n"),
        ):
            with self.subTest(helper=helper):
                result = self.run_helper(
                    'codex() { printf "<%s>\\n" "$@"; }; '
                    + helper + ' "two words" --help'
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, expected)

    def test_reports_missing_codex(self):
        for helper in ("ai", "ai-resume"):
            with self.subTest(helper=helper):
                result = self.run_helper(helper)
                self.assertEqual(result.returncode, 1)
                self.assertEqual(result.stdout, "")
                self.assertEqual(result.stderr, f"{helper}: codex is not available\n")

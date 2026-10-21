from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]


class CodexAliasesTest(unittest.TestCase):
    def test_launch_modes_preserve_arguments_and_exit_status(self):
        for shell in ("bash", "zsh"):
            for alias, flag in (
                ("codex-core", "--disable"),
                ("codex-extra", "--enable"),
            ):
                for arguments, forwarded in (
                    ("", []),
                    ('"two words" --help', ["two words", "--help"]),
                    ("resume --last", ["resume", "--last"]),
                ):
                    for exit_status in (0, 23):
                        with self.subTest(shell=shell, alias=alias,
                                          arguments=arguments, status=exit_status):
                            script = (
                                'if [ -n "${BASH_VERSION:-}" ]; then '
                                'shopt -s expand_aliases; fi\n'
                                'source "$1"\n'
                                'codex() { printf "<%s>\\n" "$@"; return '
                                + str(exit_status) + '; }\n'
                                'eval "$2"\n'
                            )
                            result = subprocess.run(
                                [shell, "-f", "-c", script, shell,
                                 str(ROOT / "sh" / "aliases.sh"),
                                 alias + " " + arguments],
                                text=True, capture_output=True, check=False,
                            )
                            expected = [flag, "apps", flag, "plugins"] + forwarded
                            self.assertEqual(result.returncode, exit_status,
                                             result.stderr)
                            self.assertEqual(result.stdout,
                                             "".join(f"<{arg}>\n" for arg in expected))
                            self.assertEqual(result.stderr, "")

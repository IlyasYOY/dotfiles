import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
LAUNCHER = ROOT / "bin" / "tmux-scout-picker"


class ScoutPickerTest(unittest.TestCase):
    def test_overrides_layout_and_preserves_picker_contract(self):
        with tempfile.TemporaryDirectory(prefix="scout picker ") as directory:
            root = Path(directory)
            picker = root / "scripts" / "picker" / "picker.sh"
            picker.parent.mkdir(parents=True)
            picker.write_text(
                '#!/usr/bin/env bash\n'
                'fzf --tmux center,85%,12 --preview old-preview '
                '--preview-window right:50% --bind "ctrl-r:reload(true)" "$@"\n'
            )
            fake_fzf = root / "fzf"
            fake_fzf.write_text(
                '#!/usr/bin/env python3\n'
                'import json, os, subprocess, sys\n'
                'if os.environ.get("SCOUT_TEST_INNER"):\n'
                '    print(json.dumps(sys.argv[1:]))\n'
                'else:\n'
                '    inner = subprocess.check_output(["bash", "-c", '
                '"SCOUT_TEST_INNER=1 PICKER_EXIT=0 fzf --filter inner"], text=True)\n'
                '    print(json.dumps({"args": sys.argv[1:], "inner": json.loads(inner)}))\n'
                'sys.exit(int(os.environ.get("PICKER_EXIT", "0")))\n'
            )
            fake_fzf.chmod(0o755)
            env = dict(os.environ, SCOUT_DIR=str(root), PATH=f"{root}:{os.environ['PATH']}")
            for exit_code in (0, 130):
                with self.subTest(exit_code=exit_code):
                    env["PICKER_EXIT"] = str(exit_code)
                    result = subprocess.run(
                        [str(LAUNCHER), "--query", "two words"],
                        env=env, text=True, capture_output=True, check=False,
                    )
                    self.assertEqual(result.returncode, exit_code, result.stderr)
                    output = json.loads(result.stdout)
                    self.assertEqual(output["inner"], ["--filter", "inner"])
                    args = output["args"]
                    self.assertEqual(args[:10], [
                        "--tmux", "center,85%,12", "--preview", "old-preview",
                        "--preview-window", "right:50%", "--bind", "ctrl-r:reload(true)",
                        "--query", "two words",
                    ])
                    overrides = dict(zip(args[10::2], args[11::2]))
                    self.assertEqual(overrides["--tmux"], "center,100%,100%,border-native")
                    self.assertEqual(overrides["--preview-window"], "hidden")
                    self.assertEqual(overrides["--preview"], "")
                    self.assertNotIn("--bind", overrides)
                    self.assertNotIn("--footer", overrides)


if __name__ == "__main__":
    unittest.main()

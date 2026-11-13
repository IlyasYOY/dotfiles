from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]


class WorkbenchOrchestrationTest(unittest.TestCase):
    def test_targets_delegate_only_to_neovim_despite_legacy_agent_override(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            log = root / "calls.log"
            nvim = root / "nvim-workbench"
            agent = root / "agent-workbench"

            for name, workbench in (("nvim", nvim), ("agent", agent)):
                workbench.mkdir()
                (workbench / "Makefile").write_text(
                    textwrap.dedent(
                        f"""\
                        install:
                        \t@printf '{name} install\\n' >> '$(WORKBENCH_TEST_LOG)'
                        update:
                        \t@printf '{name} update\\n' >> '$(WORKBENCH_TEST_LOG)'
                        """
                    )
                )

            environment = os.environ.copy()
            environment.update(
                {
                    "ILYASYOY_NVIM_WORKBENCH_DIR": str(nvim),
                    "ILYASYOY_AGENT_WORKBENCH_DIR": str(agent),
                    "WORKBENCH_TEST_LOG": str(log),
                }
            )

            # A retired checkout must not receive install/update calls; a missing
            # one must not be cloned even when an old shell exports its override.
            binaries = root / "bin"
            binaries.mkdir()
            git = binaries / "git"
            git.write_text(
                '#!/bin/sh\n'
                'if [ "$1" = ls-files ]; then exit 0; fi\n'
                'printf "unexpected git call\\n" >> "$WORKBENCH_TEST_LOG"\n'
                'exit 97\n'
            )
            git.chmod(0o755)
            environment["PATH"] = f"{binaries}{os.pathsep}{environment['PATH']}"
            for exists in (True, False):
                with self.subTest(agent_checkout_exists=exists):
                    if not exists:
                        (agent / "Makefile").unlink()
                        agent.rmdir()
                    log.unlink(missing_ok=True)
                    for action in ("install", "update"):
                        subprocess.run(
                            ["make", f"{action}-workbenches"],
                            cwd=REPO_ROOT,
                            env=environment,
                            check=True,
                            capture_output=True,
                            text=True,
                        )

                    self.assertEqual(
                        log.read_text().splitlines(),
                        ["nvim install", "nvim update"],
                    )
                    self.assertEqual(agent.exists(), exists)


if __name__ == "__main__":
    unittest.main()

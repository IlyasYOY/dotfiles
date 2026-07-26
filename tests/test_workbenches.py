from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = REPO_ROOT / "sh" / "setup" / "workbenches.sh"


class WorkbenchOrchestrationTest(unittest.TestCase):
    def test_install_and_update_delegate_to_both_workbenches(self) -> None:
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

            subprocess.run(
                [str(SCRIPT), "install"],
                cwd=REPO_ROOT,
                env=environment,
                check=True,
                capture_output=True,
                text=True,
            )
            subprocess.run(
                [str(SCRIPT), "update"],
                cwd=REPO_ROOT,
                env=environment,
                check=True,
                capture_output=True,
                text=True,
            )

            self.assertEqual(
                log.read_text().splitlines(),
                [
                    "nvim install",
                    "agent install",
                    "nvim update",
                    "agent update",
                ],
            )


if __name__ == "__main__":
    unittest.main()

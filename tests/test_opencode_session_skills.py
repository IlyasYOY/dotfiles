from __future__ import annotations

import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[1]
SESSION_HARDENER_COLLECT = (
    REPO_ROOT
    / "config/opencode/skills/session-hardener/scripts/collect_current_session.py"
)


def _create_opencode_schema(connection: sqlite3.Connection) -> None:
    connection.executescript("""
        CREATE TABLE project (
            id TEXT PRIMARY KEY,
            worktree TEXT NOT NULL,
            vcs TEXT,
            name TEXT,
            time_created INTEGER NOT NULL,
            time_updated INTEGER NOT NULL,
            time_initialized INTEGER,
            sandboxes TEXT NOT NULL,
            commands TEXT
        );
        CREATE TABLE session (
            id TEXT PRIMARY KEY,
            project_id TEXT NOT NULL,
            workspace_id TEXT,
            parent_id TEXT,
            slug TEXT NOT NULL,
            directory TEXT NOT NULL,
            path TEXT,
            title TEXT NOT NULL,
            version TEXT NOT NULL,
            share_url TEXT,
            summary_additions INTEGER,
            summary_deletions INTEGER,
            summary_files INTEGER,
            summary_diffs TEXT,
            metadata TEXT,
            cost REAL DEFAULT 0 NOT NULL,
            tokens_input INTEGER DEFAULT 0 NOT NULL,
            tokens_output INTEGER DEFAULT 0 NOT NULL,
            tokens_reasoning INTEGER DEFAULT 0 NOT NULL,
            tokens_cache_read INTEGER DEFAULT 0 NOT NULL,
            tokens_cache_write INTEGER DEFAULT 0 NOT NULL,
            revert TEXT,
            permission TEXT,
            agent TEXT,
            model TEXT,
            time_created INTEGER NOT NULL,
            time_updated INTEGER NOT NULL,
            time_compacting INTEGER,
            time_archived INTEGER
        );
        CREATE TABLE message (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            time_created INTEGER NOT NULL,
            time_updated INTEGER NOT NULL,
            data TEXT NOT NULL,
            FOREIGN KEY (session_id) REFERENCES session(id) ON DELETE CASCADE
        );
        CREATE TABLE part (
            id TEXT PRIMARY KEY,
            message_id TEXT NOT NULL,
            session_id TEXT NOT NULL,
            time_created INTEGER NOT NULL,
            time_updated INTEGER NOT NULL,
            data TEXT NOT NULL,
            FOREIGN KEY (message_id) REFERENCES message(id) ON DELETE CASCADE
        );
        CREATE TABLE session_message (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            type TEXT NOT NULL,
            seq INTEGER NOT NULL,
            time_created INTEGER NOT NULL,
            time_updated INTEGER NOT NULL,
            data TEXT NOT NULL,
            FOREIGN KEY (session_id) REFERENCES session(id) ON DELETE CASCADE
        );
        CREATE TABLE todo (
            session_id TEXT NOT NULL,
            content TEXT NOT NULL,
            status TEXT NOT NULL,
            priority TEXT NOT NULL,
            position INTEGER NOT NULL,
            time_created INTEGER NOT NULL,
            time_updated INTEGER NOT NULL,
            PRIMARY KEY(session_id, position),
            FOREIGN KEY (session_id) REFERENCES session(id) ON DELETE CASCADE
        );
        CREATE TABLE session_input (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            prompt TEXT NOT NULL,
            delivery TEXT NOT NULL,
            admitted_seq INTEGER NOT NULL,
            promoted_seq INTEGER,
            time_created INTEGER NOT NULL,
            FOREIGN KEY (session_id) REFERENCES session(id) ON DELETE CASCADE
        );
    """)


def create_opencode_state(
    opencode_home: Path,
    project_dir: Path,
    *,
    session_id: str = "ses-test-1",
    project_id: str = "project-test",
) -> None:
    db_path = opencode_home / "opencode.db"
    connection = sqlite3.connect(str(db_path))
    try:
        _create_opencode_schema(connection)

        connection.execute(
            "INSERT INTO project (id, worktree, name, time_created, time_updated, sandboxes)"
            " VALUES (?, ?, ?, 1_782_000_000_000, 1_782_000_000_000, '{}')",
            (project_id, str(project_dir), "test-project"),
        )

        connection.execute(
            """INSERT INTO session (
                id, project_id, slug, directory, title, version,
                cost, tokens_input, tokens_output, tokens_reasoning,
                tokens_cache_read, tokens_cache_write,
                agent, model,
                time_created, time_updated
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                session_id,
                project_id,
                "test-slug",
                str(project_dir),
                "Test session title",
                "1.17.5",
                0.0,
                5000,
                1200,
                300,
                10000,
                0,
                "build",
                json.dumps({"providerID": "llm-proxy", "id": "test-model"}),
                1_782_000_000_000,
                1_782_000_001_000,
            ),
        )

        msg_id = "msg-test-1"
        connection.execute(
            "INSERT INTO message (id, session_id, time_created, time_updated, data)"
            " VALUES (?, ?, 1_782_000_000_000, 1_782_000_000_000, ?)",
            (msg_id, session_id, json.dumps({"role": "user", "agent": "build"})),
        )
        connection.execute(
            "INSERT INTO part (id, message_id, session_id, time_created, time_updated, data)"
            " VALUES (?, ?, ?, 1_782_000_000_000, 1_782_000_000_000, ?)",
            (
                "prt-test-1",
                msg_id,
                session_id,
                json.dumps({"type": "text", "text": "please review token=s3cr3tvalue"}),
            ),
        )

        msg2_id = "msg-test-2"
        connection.execute(
            "INSERT INTO message (id, session_id, time_created, time_updated, data)"
            " VALUES (?, ?, 1_782_000_000_100, 1_782_000_000_100, ?)",
            (msg2_id, session_id, json.dumps({"role": "assistant", "agent": "build"})),
        )
        connection.execute(
            "INSERT INTO part (id, message_id, session_id, time_created, time_updated, data)"
            " VALUES (?, ?, ?, 1_782_000_000_100, 1_782_000_000_100, ?)",
            (
                "prt-test-2",
                msg2_id,
                session_id,
                json.dumps({"type": "reasoning", "text": "Let me think about this problem."}),
            ),
        )
        connection.execute(
            "INSERT INTO part (id, message_id, session_id, time_created, time_updated, data)"
            " VALUES (?, ?, ?, 1_782_000_000_200, 1_782_000_000_200, ?)",
            (
                "prt-test-3",
                msg2_id,
                session_id,
                json.dumps({"type": "text", "text": "I found the issue."}),
            ),
        )

        msg3_id = "msg-test-3"
        connection.execute(
            "INSERT INTO message (id, session_id, time_created, time_updated, data)"
            " VALUES (?, ?, 1_782_000_000_300, 1_782_000_000_300, ?)",
            (msg3_id, session_id, json.dumps({"role": "assistant", "agent": "build"})),
        )
        connection.execute(
            "INSERT INTO part (id, message_id, session_id, time_created, time_updated, data)"
            " VALUES (?, ?, ?, 1_782_000_000_300, 1_782_000_000_300, ?)",
            (
                "prt-test-4",
                msg3_id,
                session_id,
                json.dumps({
                    "type": "tool",
                    "tool": "bash",
                    "callID": "call-1",
                    "state": {
                        "status": "completed",
                        "input": {
                            "description": "Run failing command",
                            "command": "make fail",
                        },
                        "output": "Process exited with code 2\nOutput:\nTraceback most recent call last",
                    },
                }),
            ),
        )

        connection.execute(
            "INSERT INTO session_message (id, session_id, type, seq, time_created, time_updated, data)"
            " VALUES (?, ?, ?, ?, ?, ?, ?)",
            (
                "sm-test-1",
                session_id,
                "model-switched",
                1,
                1_782_000_000_000,
                1_782_000_000_000,
                json.dumps({"model": {"providerID": "llm-proxy", "id": "test-model"}}),
            ),
        )

        connection.execute(
            "INSERT INTO todo (session_id, content, status, priority, position, time_created, time_updated)"
            " VALUES (?, ?, ?, ?, ?, ?, ?)",
            (session_id, "Write tests", "completed", "high", 0, 1_782_000_000_000, 1_782_000_000_100),
        )

        connection.commit()
    finally:
        connection.close()


def write_log(opencode_home: Path, session_id: str) -> None:
    log_dir = opencode_home / "log"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_path = log_dir / "opencode.log"
    log_path.write_text(
        "timestamp=2026-06-21T10:00:00.000Z level=INFO run=run1"
        f" message=evaluated permission=bash"
        f' pattern="make *" action.action=allow'
        f" session.id={session_id}\n"
        "timestamp=2026-06-21T10:00:01.000Z level=INFO run=run1"
        f" message=asking id=per-1 permission=bash"
        f' patterns=\'["make fail"]\''
        f" session.id={session_id}\n"
        "timestamp=2026-06-21T10:00:02.000Z level=INFO run=run1"
        f" message=evaluated permission=edit"
        f' pattern="*" action.action=ask'
        f" session.id={session_id}\n"
        "timestamp=2026-06-21T10:00:03.000Z level=WARN run=run1"
        f" message=some_warning extra=detail"
        f" session.id={session_id}\n",
        encoding="utf-8",
    )


def run_collector(
    *args: str,
    env: dict[str, str] | None = None,
) -> dict[str, object]:
    result = subprocess.run(
        [sys.executable, str(SESSION_HARDENER_COLLECT), *args],
        cwd=REPO_ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        raise AssertionError(
            f"collector failed with {result.returncode}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return json.loads(result.stdout)


class OpenCodeSessionSkillTests(unittest.TestCase):
    def test_collects_session_by_id(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            opencode_home = root / "opencode-home"
            project = root / "project"
            opencode_home.mkdir()
            project.mkdir()
            create_opencode_state(opencode_home, project)
            write_log(opencode_home, "ses-test-1")

            data = run_collector(
                "--opencode-home", str(opencode_home),
                "--session-id", "ses-test-1",
                "--pretty",
            )

        self.assertTrue(data["read_only"])
        self.assertEqual(data["source"], "session-id")
        self.assertEqual(data["session"]["id"], "ses-test-1")
        self.assertEqual(data["session"]["title"], "Test session title")
        self.assertEqual(data["session"]["model"], "llm-proxy/test-model")
        self.assertEqual(data["session"]["tokens_input"], 5000)
        self.assertEqual(data["session"]["tokens_output"], 1200)
        self.assertEqual(data["session"]["tokens_reasoning"], 300)
        self.assertEqual(data["session"]["agent"], "build")
        self.assertEqual(data["session"]["version"], "1.17.5")

    def test_redacts_secrets_in_messages(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            opencode_home = root / "opencode-home"
            project = root / "project"
            opencode_home.mkdir()
            project.mkdir()
            create_opencode_state(opencode_home, project)

            data = run_collector(
                "--opencode-home", str(opencode_home),
                "--session-id", "ses-test-1",
                "--pretty",
            )

        self.assertIn("token=[REDACTED]", data["messages"][0]["text"])
        self.assertNotIn("s3cr3tvalue", json.dumps(data))

    def test_collects_tool_calls_and_failures(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            opencode_home = root / "opencode-home"
            project = root / "project"
            opencode_home.mkdir()
            project.mkdir()
            create_opencode_state(opencode_home, project)

            data = run_collector(
                "--opencode-home", str(opencode_home),
                "--session-id", "ses-test-1",
                "--pretty",
            )

        self.assertTrue(any(c["name"] == "bash" for c in data["tool_calls"]))
        bash_calls = [c for c in data["tool_calls"] if c["name"] == "bash"]
        self.assertTrue(
            any(c["commands"] == ["make fail"] for c in bash_calls),
            f"tool_calls: {json.dumps(data['tool_calls'], indent=2)}",
        )
        self.assertGreaterEqual(len(data["command_failures"]), 1)
        self.assertEqual(data["command_failures"][0]["exit_code"], 2)

    def test_collects_reasoning_summaries(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            opencode_home = root / "opencode-home"
            project = root / "project"
            opencode_home.mkdir()
            project.mkdir()
            create_opencode_state(opencode_home, project)

            data = run_collector(
                "--opencode-home", str(opencode_home),
                "--session-id", "ses-test-1",
                "--pretty",
            )

        self.assertTrue(any("Let me think" in s for s in data["summaries"]))

    def test_collects_model_switches(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            opencode_home = root / "opencode-home"
            project = root / "project"
            opencode_home.mkdir()
            project.mkdir()
            create_opencode_state(opencode_home, project)

            data = run_collector(
                "--opencode-home", str(opencode_home),
                "--session-id", "ses-test-1",
                "--pretty",
            )

        self.assertEqual(len(data["model_switches"]), 1)
        self.assertEqual(data["model_switches"][0]["model"], "llm-proxy/test-model")

    def test_collects_todos(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            opencode_home = root / "opencode-home"
            project = root / "project"
            opencode_home.mkdir()
            project.mkdir()
            create_opencode_state(opencode_home, project)

            data = run_collector(
                "--opencode-home", str(opencode_home),
                "--session-id", "ses-test-1",
                "--pretty",
            )

        self.assertEqual(len(data["todos"]), 1)
        self.assertEqual(data["todos"][0]["content"], "Write tests")
        self.assertEqual(data["todos"][0]["status"], "completed")
        self.assertEqual(data["todos"][0]["priority"], "high")

    def test_collects_log_data(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            opencode_home = root / "opencode-home"
            project = root / "project"
            opencode_home.mkdir()
            project.mkdir()
            create_opencode_state(opencode_home, project)
            write_log(opencode_home, "ses-test-1")

            data = run_collector(
                "--opencode-home", str(opencode_home),
                "--session-id", "ses-test-1",
                "--pretty",
            )

        self.assertIn("bash:allow", data["log"]["permission_stats"])
        self.assertIn("edit:ask", data["log"]["permission_stats"])
        self.assertEqual(len(data["log"]["approval_requests"]), 1)
        self.assertEqual(data["log"]["approval_requests"][0]["permission"], "bash")
        self.assertEqual(len(data["log"]["log_errors"]), 1)
        self.assertEqual(data["log"]["log_errors"][0]["level"], "WARN")

    def test_latest_for_cwd_finds_session(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            opencode_home = root / "opencode-home"
            project = root / "project"
            opencode_home.mkdir()
            project.mkdir()
            create_opencode_state(opencode_home, project)

            data = run_collector(
                "--opencode-home", str(opencode_home),
                "--latest-for-cwd", str(project),
                "--pretty",
            )

        self.assertEqual(data["source"], "latest-for-cwd")
        self.assertEqual(data["session"]["id"], "ses-test-1")

    def test_nonexistent_session_errors(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            opencode_home = root / "opencode-home"
            opencode_home.mkdir()
            db_path = opencode_home / "opencode.db"
            connection = sqlite3.connect(str(db_path))
            try:
                _create_opencode_schema(connection)
                connection.commit()
            finally:
                connection.close()

            result = subprocess.run(
                [sys.executable, str(SESSION_HARDENER_COLLECT),
                 "--opencode-home", str(opencode_home),
                 "--session-id", "nonexistent",
                 "--pretty"],
                cwd=REPO_ROOT,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )

        self.assertEqual(result.returncode, 1)
        error_data = json.loads(result.stderr)
        self.assertTrue(error_data["read_only"])
        self.assertIn("session not found", error_data["error"])

    def test_respects_event_limits(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            opencode_home = root / "opencode-home"
            project = root / "project"
            opencode_home.mkdir()
            project.mkdir()
            create_opencode_state(opencode_home, project)

            data = run_collector(
                "--opencode-home", str(opencode_home),
                "--session-id", "ses-test-1",
                "--max-events", "1",
                "--pretty",
            )

        self.assertTrue(len(data["messages"]) <= 1)
        self.assertTrue(len(data["tool_calls"]) <= 1)


if __name__ == "__main__":
    unittest.main()

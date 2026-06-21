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
AI_SESSION_COLLECT = (
    REPO_ROOT / "config/codex/skills/ai-session-coach/scripts/collect_sessions.py"
)
AI_SESSION_ARCHIVE = (
    REPO_ROOT / "config/codex/skills/ai-session-coach/scripts/archive_sessions.py"
)
SESSION_HARDENER_COLLECT = (
    REPO_ROOT
    / "config/codex/skills/session-hardener/scripts/collect_current_session.py"
)


def create_state_database(codex_home: Path) -> None:
    connection = sqlite3.connect(codex_home / "state_5.sqlite")
    try:
        connection.execute(
            """
            CREATE TABLE threads (
                id TEXT PRIMARY KEY,
                rollout_path TEXT,
                created_at_ms INTEGER,
                created_at INTEGER,
                updated_at_ms INTEGER,
                updated_at INTEGER,
                source TEXT,
                model_provider TEXT,
                cwd TEXT,
                title TEXT,
                sandbox_policy TEXT,
                approval_mode TEXT,
                tokens_used INTEGER,
                archived INTEGER,
                archived_at INTEGER,
                git_sha TEXT,
                git_branch TEXT,
                git_origin_url TEXT,
                cli_version TEXT,
                first_user_message TEXT,
                model TEXT,
                reasoning_effort TEXT,
                thread_source TEXT
            )
            """
        )
        connection.commit()
    finally:
        connection.close()


def insert_thread(codex_home: Path, **overrides: object) -> None:
    values = {
        "id": "thread-1",
        "rollout_path": None,
        "created_at_ms": 1_782_000_000_000,
        "created_at": None,
        "updated_at_ms": 1_782_000_001_000,
        "updated_at": None,
        "source": "codex",
        "model_provider": "openai",
        "cwd": str(codex_home),
        "title": "Test session",
        "sandbox_policy": "workspace-write",
        "approval_mode": "on-request",
        "tokens_used": 123,
        "archived": 0,
        "archived_at": None,
        "git_sha": "abc123",
        "git_branch": "main",
        "git_origin_url": "git@example.com:test/repo.git",
        "cli_version": "test",
        "first_user_message": "first message",
        "model": "gpt-test",
        "reasoning_effort": "high",
        "thread_source": "cli",
    }
    values.update(overrides)

    connection = sqlite3.connect(codex_home / "state_5.sqlite")
    try:
        columns = ", ".join(values)
        placeholders = ", ".join(f":{name}" for name in values)
        connection.execute(
            f"INSERT INTO threads ({columns}) VALUES ({placeholders})",
            values,
        )
        connection.commit()
    finally:
        connection.close()


def write_rollout(path: Path, events: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "".join(json.dumps(event) + "\n" for event in events),
        encoding="utf-8",
    )


def sample_rollout_events() -> list[dict[str, object]]:
    return [
        {
            "type": "response_item",
            "timestamp": "2026-06-21T10:00:00Z",
            "payload": {
                "type": "message",
                "role": "user",
                "content": [{"text": "please inspect token=supersecretvalue"}],
            },
        },
        {
            "type": "response_item",
            "timestamp": "2026-06-21T10:00:01Z",
            "payload": {
                "type": "function_call",
                "call_id": "call-1",
                "name": "functions.exec_command",
                "arguments": json.dumps({"cmd": "make check"}),
            },
        },
        {
            "type": "response_item",
            "timestamp": "2026-06-21T10:00:02Z",
            "payload": {
                "type": "function_call_output",
                "call_id": "call-1",
                "output": "Process exited with code 2\nOutput:\n[ERROR] failed",
            },
        },
    ]


def run_json_script(
    script: Path,
    *args: str,
    env: dict[str, str] | None = None,
) -> dict[str, object]:
    result = subprocess.run(
        [sys.executable, str(script), *args],
        cwd=REPO_ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        raise AssertionError(
            f"{script.name} failed with {result.returncode}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return json.loads(result.stdout)


class CodexSessionSkillTests(unittest.TestCase):
    def test_session_hardener_collects_redacted_current_session(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            codex_home = root / "codex-home"
            project = root / "project"
            codex_home.mkdir()
            project.mkdir()
            create_state_database(codex_home)

            rollout = codex_home / "sessions" / "thread-hardener.jsonl"
            write_rollout(rollout, sample_rollout_events())
            insert_thread(
                codex_home,
                id="thread-hardener",
                rollout_path=str(rollout),
                cwd=str(project),
                first_user_message="please inspect token=supersecretvalue",
                title="Harden repo",
            )

            data = run_json_script(
                SESSION_HARDENER_COLLECT,
                "--codex-home",
                str(codex_home),
                "--thread-id",
                "thread-hardener",
                "--pretty",
            )

        self.assertTrue(data["read_only"])
        self.assertEqual(data["thread"]["id"], "thread-hardener")
        self.assertEqual(data["session"]["command_failures"][0]["exit_code"], 2)
        self.assertIn("[REDACTED]", data["session"]["messages"][0]["text"])
        self.assertNotIn("supersecretvalue", json.dumps(data))

    def test_ai_session_coach_writes_filtered_project_packs(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            codex_home = root / "codex-home"
            project = root / "project"
            out_dir = root / "out"
            codex_home.mkdir()
            project.mkdir()
            create_state_database(codex_home)

            keep_rollout = codex_home / "sessions" / "thread-keep.jsonl"
            write_rollout(keep_rollout, sample_rollout_events())
            insert_thread(
                codex_home,
                id="thread-keep",
                rollout_path=str(keep_rollout),
                cwd=str(project),
                first_user_message="keep token=supersecretvalue",
                title="Keep session",
                updated_at_ms=1_782_000_003_000,
            )
            insert_thread(
                codex_home,
                id="thread-current",
                cwd=str(project),
                first_user_message="current session",
                title="Current session",
                updated_at_ms=1_782_000_002_000,
            )
            insert_thread(
                codex_home,
                id="thread-archived",
                cwd=str(project),
                archived=1,
                first_user_message="archived session",
                title="Archived session",
                updated_at_ms=1_782_000_001_000,
            )

            env = os.environ.copy()
            env["CODEX_THREAD_ID"] = "thread-current"
            result = run_json_script(
                AI_SESSION_COLLECT,
                "--codex-home",
                str(codex_home),
                "--unarchived",
                "--exclude-current-thread",
                "--out-dir",
                str(out_dir),
                "--analysis-focus",
                "find friction",
                "--pretty",
                env=env,
            )

            manifest_path = Path(result["manifest_path"])
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            project_pack_path = out_dir / manifest["projects"][0]["project_file"]
            project_pack = json.loads(project_pack_path.read_text(encoding="utf-8"))
            dry_run = run_json_script(
                AI_SESSION_ARCHIVE,
                "--manifest",
                str(manifest_path),
                "--codex-home",
                str(codex_home),
                "--pretty",
                env=env,
            )

            connection = sqlite3.connect(codex_home / "state_5.sqlite")
            try:
                archived = connection.execute(
                    "SELECT archived FROM threads WHERE id = ?",
                    ("thread-keep",),
                ).fetchone()[0]
            finally:
                connection.close()
            rollout_still_exists = keep_rollout.exists()

        self.assertEqual(result["project_pack_count"], 1)
        self.assertEqual(result["counts"]["loaded_sessions"], 1)
        self.assertEqual(manifest["projects"][0]["session_ids"], ["thread-keep"])
        self.assertEqual(project_pack["project"]["session_ids"], ["thread-keep"])
        self.assertNotIn("supersecretvalue", json.dumps(project_pack))
        self.assertEqual(dry_run["mode"], "dry-run")
        self.assertFalse(dry_run["applied"])
        self.assertEqual(dry_run["summary"]["archived"], 1)
        self.assertEqual(archived, 0)
        self.assertTrue(rollout_still_exists)


if __name__ == "__main__":
    unittest.main()

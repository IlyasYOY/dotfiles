from __future__ import annotations

import contextlib
import datetime as dt
import importlib.util
import io
import json
import os
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest import mock


SKILL_DIR = Path(__file__).resolve().parents[1]


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load module from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


collect_sessions = load_module(
    "ai_session_coach_collect_sessions",
    SKILL_DIR / "scripts" / "collect_sessions.py",
)
record_checkpoint = load_module(
    "ai_session_coach_record_checkpoint",
    SKILL_DIR / "scripts" / "record_checkpoint.py",
)


THREAD_SCHEMA = """
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


class SessionCoachToolsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root_path = Path(self.temp_dir.name)
        self.codex_home = self.root_path / "codex"
        self.codex_home.mkdir()
        self.db_path = self.codex_home / "state_5.sqlite"
        with contextlib.closing(sqlite3.connect(self.db_path)) as connection:
            connection.execute(THREAD_SCHEMA)
            connection.commit()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def insert_thread(
        self,
        thread_id: str,
        prompt: str,
        *,
        thread_source: str = "user",
        rollout: bool = False,
        archived: bool = False,
        updated_at_ms: int = 1_750_000_000_000,
    ) -> None:
        rollout_path = None
        if rollout:
            sessions_dir = self.codex_home / "sessions"
            sessions_dir.mkdir(exist_ok=True)
            path = sessions_dir / f"rollout-{thread_id}.jsonl"
            path.write_text("", encoding="utf-8")
            rollout_path = str(path)

        values = {
            "id": thread_id,
            "rollout_path": rollout_path,
            "created_at_ms": updated_at_ms,
            "updated_at_ms": updated_at_ms,
            "source": "cli",
            "cwd": "/workspace/project",
            "title": prompt,
            "approval_mode": "on-request",
            "tokens_used": 10,
            "archived": int(archived),
            "first_user_message": prompt,
            "model": "test-model",
            "thread_source": thread_source,
        }
        columns = ", ".join(values)
        placeholders = ", ".join("?" for _ in values)
        with contextlib.closing(sqlite3.connect(self.db_path)) as connection:
            connection.execute(
                f"INSERT INTO threads ({columns}) VALUES ({placeholders})",
                tuple(values.values()),
            )
            connection.commit()

    def write_checkpoint(self, updated_through_ms: int) -> Path:
        path = self.codex_home / collect_sessions.CHECKPOINT_FILENAME
        timestamp = dt.datetime.fromtimestamp(
            updated_through_ms / 1000,
            tz=dt.timezone.utc,
        ).isoformat()
        path.write_text(
            json.dumps(
                {
                    "version": 1,
                    "last_execution_at": timestamp,
                    "sessions_updated_through": timestamp,
                    "snapshot_id": "previous",
                }
            ),
            encoding="utf-8",
        )
        return path

    def run_collector(
        self,
        out_dir: Path,
        *extra_args: str,
        current_thread_id: str = "current",
    ) -> dict:
        args = [
            "--incremental",
            "--exclude-current-thread",
            "--codex-home",
            str(self.codex_home),
            "--out-dir",
            str(out_dir),
            *extra_args,
        ]
        stdout = io.StringIO()
        with mock.patch.dict(os.environ, {"CODEX_THREAD_ID": current_thread_id}):
            with contextlib.redirect_stdout(stdout):
                result = collect_sessions.main(args)
        self.assertEqual(result, 0)
        return json.loads((out_dir / "manifest.json").read_text(encoding="utf-8"))

    def test_first_incremental_run_uses_unarchived_migration_baseline(self) -> None:
        self.insert_thread("normal", "Implement the feature")
        self.insert_thread("already-reviewed", "Old work", archived=True)
        self.insert_thread("guardian", "Approval review", thread_source="subagent")
        self.insert_thread(
            "review-fallback",
            collect_sessions.APPROVAL_REVIEW_PROMPT,
        )
        self.insert_thread("coach", "$ai-session-coach")
        self.insert_thread("daily", "Use $daily-session-report for today")
        self.insert_thread("model", "/model gpt-test")
        self.insert_thread("current", "Current task")

        manifest = self.run_collector(self.root_path / "default")

        self.assertTrue(manifest["filters"]["initial_unarchived_baseline"])
        self.assertFalse(manifest["filters"]["checkpoint_exists"])
        self.assertEqual(
            set(manifest["projects"][0]["session_ids"]),
            {"normal", "daily"},
        )
        self.assertEqual(
            {session["id"] for session in manifest["internal_sessions"]},
            {"guardian", "review-fallback", "coach", "model"},
        )
        self.assertEqual(
            manifest["counts"]["internal_exclusion_reasons"],
            {
                "approval_review_prompt": 1,
                "codex_subagent": 1,
                "model_switch": 1,
                "session_coach_housekeeping": 1,
            },
        )

    def test_checkpoint_uses_updated_time_and_includes_archived_sessions(self) -> None:
        cutoff_ms = 1_750_000_000_000
        self.write_checkpoint(cutoff_ms)
        self.insert_thread("old", "Old", updated_at_ms=cutoff_ms - 1)
        self.insert_thread("boundary", "Boundary", updated_at_ms=cutoff_ms)
        self.insert_thread("new", "New", updated_at_ms=cutoff_ms + 1)
        self.insert_thread(
            "archived-new",
            "Archived but changed",
            archived=True,
            updated_at_ms=cutoff_ms + 2,
        )
        self.insert_thread("current", "Current", updated_at_ms=cutoff_ms + 3)

        manifest = self.run_collector(self.root_path / "incremental")

        self.assertFalse(manifest["filters"]["initial_unarchived_baseline"])
        self.assertTrue(manifest["filters"]["checkpoint_exists"])
        self.assertEqual(
            set(manifest["projects"][0]["session_ids"]),
            {"boundary", "new", "archived-new"},
        )

        later_manifest = self.run_collector(
            self.root_path / "former-current",
            current_thread_id="different-current",
        )
        self.assertIn("current", later_manifest["projects"][0]["session_ids"])

    def test_include_internal_restores_filtered_sessions(self) -> None:
        self.insert_thread("normal", "Implement the feature")
        self.insert_thread("guardian", "Approval review", thread_source="subagent")
        self.insert_thread("coach", "$ai-session-coach")
        self.insert_thread("current", "Current task")

        manifest = self.run_collector(
            self.root_path / "included",
            "--include-internal",
        )

        self.assertEqual(manifest["internal_sessions"], [])
        self.assertEqual(
            set(manifest["projects"][0]["session_ids"]),
            {"normal", "guardian", "coach"},
        )

    def test_record_checkpoint_preserves_sessions_and_enables_empty_next_run(self) -> None:
        self.insert_thread("normal", "Implement the feature", rollout=True)
        manifest_path = self.root_path / "snapshot" / "manifest.json"
        manifest = self.run_collector(manifest_path.parent)
        rollout_path = self.codex_home / "sessions" / "rollout-normal.jsonl"
        executed_at = dt.datetime(2026, 7, 14, 12, 0, tzinfo=dt.timezone.utc)

        checkpoint_path, checkpoint = record_checkpoint.record_checkpoint(
            manifest_path=manifest_path,
            executed_at=executed_at,
        )

        self.assertEqual(
            checkpoint["last_execution_at"],
            "2026-07-14T12:00:00+00:00",
        )
        self.assertEqual(
            checkpoint["sessions_updated_through"],
            manifest["snapshot_started_at"],
        )
        self.assertEqual(
            checkpoint_path,
            (self.codex_home / "ai-session-coach-state.json").resolve(),
        )
        self.assertTrue(rollout_path.exists())
        with contextlib.closing(sqlite3.connect(self.db_path)) as connection:
            archived = connection.execute(
                "SELECT archived FROM threads WHERE id = 'normal'"
            ).fetchone()[0]
        self.assertEqual(archived, 0)

        next_manifest_path = self.root_path / "next" / "manifest.json"
        next_manifest = self.run_collector(next_manifest_path.parent)
        self.assertEqual(next_manifest["projects"], [])
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            exit_code = record_checkpoint.main(
                ["--manifest", str(next_manifest_path), "--pretty"]
            )
        self.assertEqual(exit_code, 0)
        cli_output = json.loads(stdout.getvalue())
        self.assertEqual(
            Path(cli_output["checkpoint_path"]),
            checkpoint_path,
        )

    def test_checkpoint_rejects_partial_and_stale_manifests(self) -> None:
        self.insert_thread("normal", "Implement the feature")
        manifest = self.run_collector(self.root_path / "snapshot")

        unsafe_filters = (
            {"projects": ["project"]},
            {"since": "2026-01-01"},
            {"until": "2026-01-02"},
            {"max_sessions": 10},
            {"custom_exclude_thread_ids": ["hidden"]},
            {"checkpoint_ignored": True},
        )
        for overrides in unsafe_filters:
            with self.subTest(overrides=overrides):
                partial = json.loads(json.dumps(manifest))
                partial["filters"].update(overrides)
                with self.assertRaises(ValueError):
                    record_checkpoint.build_checkpoint(
                        manifest=partial,
                        existing=None,
                    )

        future = dict(
            record_checkpoint.build_checkpoint(manifest=manifest, existing=None)
        )
        future["sessions_updated_through"] = "2999-01-01T00:00:00+00:00"
        with self.assertRaisesRegex(ValueError, "older than"):
            record_checkpoint.build_checkpoint(
                manifest=manifest,
                existing=future,
            )

    def test_invalid_checkpoint_fails_closed(self) -> None:
        checkpoint_path = self.codex_home / collect_sessions.CHECKPOINT_FILENAME
        checkpoint_path.write_text('{"version": 99}', encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "unsupported checkpoint version"):
            collect_sessions.load_checkpoint(checkpoint_path)


if __name__ == "__main__":
    unittest.main()

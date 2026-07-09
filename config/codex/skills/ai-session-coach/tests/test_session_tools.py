from __future__ import annotations

import contextlib
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
archive_sessions = load_module(
    "ai_session_coach_archive_sessions",
    SKILL_DIR / "scripts" / "archive_sessions.py",
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
    ) -> None:
        rollout_path = None
        if rollout:
            sessions_dir = self.codex_home / "sessions"
            sessions_dir.mkdir(exist_ok=True)
            path = sessions_dir / f"rollout-{thread_id}.jsonl"
            path.write_text("", encoding="utf-8")
            rollout_path = str(path)

        timestamp = 1_750_000_000_000
        values = {
            "id": thread_id,
            "rollout_path": rollout_path,
            "created_at_ms": timestamp,
            "updated_at_ms": timestamp,
            "source": "cli",
            "cwd": "/workspace/project",
            "title": prompt,
            "approval_mode": "on-request",
            "tokens_used": 10,
            "archived": 0,
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

    def run_collector(self, out_dir: Path, *extra_args: str) -> dict:
        args = [
            "--unarchived",
            "--exclude-current-thread",
            "--codex-home",
            str(self.codex_home),
            "--out-dir",
            str(out_dir),
            *extra_args,
        ]
        stdout = io.StringIO()
        with mock.patch.dict(os.environ, {"CODEX_THREAD_ID": "current"}):
            with contextlib.redirect_stdout(stdout):
                result = collect_sessions.main(args)
        self.assertEqual(result, 0)
        return json.loads((out_dir / "manifest.json").read_text(encoding="utf-8"))

    def test_default_filter_tracks_internal_sessions(self) -> None:
        self.insert_thread("normal", "Implement the feature")
        self.insert_thread("guardian", "Approval review", thread_source="subagent")
        self.insert_thread(
            "review-fallback",
            collect_sessions.APPROVAL_REVIEW_PROMPT,
        )
        self.insert_thread("coach", "$ai-session-coach")
        self.insert_thread("daily", "Use $daily-session-report for today")
        self.insert_thread("model", "/model gpt-test")
        self.insert_thread("current", "Current task")

        manifest = self.run_collector(Path(self.temp_dir.name) / "default")

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
        self.assertNotIn("current", archive_sessions.extract_session_ids(manifest))

    def test_include_internal_restores_filtered_sessions(self) -> None:
        self.insert_thread("normal", "Implement the feature")
        self.insert_thread("guardian", "Approval review", thread_source="subagent")
        self.insert_thread(
            "review-fallback",
            collect_sessions.APPROVAL_REVIEW_PROMPT,
        )
        self.insert_thread("coach", "$ai-session-coach")
        self.insert_thread("daily", "Use $daily-session-report for today")
        self.insert_thread("model", "/model gpt-test")
        self.insert_thread("current", "Current task")

        manifest = self.run_collector(
            Path(self.temp_dir.name) / "included",
            "--include-internal",
        )

        self.assertEqual(manifest["internal_sessions"], [])
        self.assertEqual(manifest["counts"]["internal_sessions_excluded"], 0)
        self.assertEqual(
            set(manifest["projects"][0]["session_ids"]),
            {
                "normal",
                "guardian",
                "review-fallback",
                "coach",
                "daily",
                "model",
            },
        )

    def test_archive_plan_combines_categories_without_mutation(self) -> None:
        self.insert_thread("normal", "Implement the feature", rollout=True)
        self.insert_thread(
            "guardian",
            "Approval review",
            thread_source="subagent",
            rollout=True,
        )
        self.insert_thread("current", "Current task", rollout=True)
        manifest = {
            "snapshot_id": "test-snapshot",
            "codex_home": str(self.codex_home),
            "projects": [{"session_ids": ["normal"]}],
            "internal_sessions": [
                {"id": "normal"},
                {"id": "guardian"},
                {"id": "current"},
            ],
        }

        results, summary = archive_sessions.build_plan(
            manifest=manifest,
            codex_home=self.codex_home,
            current_thread_id="current",
        )

        self.assertEqual([result["id"] for result in results], ["normal", "guardian", "current"])
        self.assertEqual(
            {result["id"]: result["category"] for result in results},
            {"normal": "analyzed", "guardian": "internal", "current": "internal"},
        )
        self.assertEqual(summary["archived"], 2)
        self.assertEqual(summary["skipped_current_thread"], 1)
        category_summary = archive_sessions.summarize_by_category(results)
        self.assertEqual(category_summary["analyzed"]["archived"], 1)
        self.assertEqual(category_summary["internal"]["archived"], 1)
        self.assertEqual(category_summary["internal"]["skipped_current_thread"], 1)
        with contextlib.closing(sqlite3.connect(self.db_path)) as connection:
            archived = connection.execute(
                "SELECT SUM(archived) FROM threads"
            ).fetchone()[0]
        self.assertEqual(archived, 0)

        manifest_path = self.root_path / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        stdout = io.StringIO()
        with mock.patch.dict(os.environ, {"CODEX_THREAD_ID": "current"}):
            with contextlib.redirect_stdout(stdout):
                exit_code = archive_sessions.main(
                    [
                        "--manifest",
                        str(manifest_path),
                        "--codex-home",
                        str(self.codex_home),
                    ]
                )
        self.assertEqual(exit_code, 0)
        dry_run = json.loads(stdout.getvalue())
        self.assertEqual(dry_run["mode"], "dry-run")
        self.assertEqual(dry_run["summary_by_category"], category_summary)
        with contextlib.closing(sqlite3.connect(self.db_path)) as connection:
            archived_after_dry_run = connection.execute(
                "SELECT SUM(archived) FROM threads"
            ).fetchone()[0]
        self.assertEqual(archived_after_dry_run, 0)


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Archive OpenCode sessions listed in an ai-session-coach snapshot manifest."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import sqlite3
import sys
from typing import Any


SUMMARY_KEYS = (
    "archived",
    "skipped_current_session",
    "already_archived",
    "errors",
)


class ArchiveFailure(RuntimeError):
    """Raised when an apply operation cannot be completed safely."""


def default_opencode_home() -> str:
    data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
    return os.environ.get("OPENCODE_HOME", os.path.join(data_home, "opencode"))


def expand_path(value: str | Path) -> Path:
    return Path(os.path.expanduser(str(value))).resolve()


def load_manifest(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("manifest must be a JSON object")
    return value


def extract_session_ids(manifest: dict[str, Any]) -> list[str]:
    seen: set[str] = set()
    session_ids: list[str] = []
    projects = manifest.get("projects", [])
    if not isinstance(projects, list):
        raise ValueError("manifest.projects must be a list")
    for project in projects:
        if not isinstance(project, dict):
            continue
        for session_id in project.get("session_ids", []):
            if not isinstance(session_id, str) or not session_id:
                continue
            if session_id in seen:
                continue
            seen.add(session_id)
            session_ids.append(session_id)
    return session_ids


def chunked(values: list[str], size: int = 800) -> list[list[str]]:
    return [values[index : index + size] for index in range(0, len(values), size)]


def fetch_sessions(db_path: Path, session_ids: list[str]) -> dict[str, dict[str, Any]]:
    if not session_ids:
        return {}

    connection = sqlite3.connect(f"{db_path.as_uri()}?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    try:
        rows_by_id: dict[str, dict[str, Any]] = {}
        for chunk in chunked(session_ids):
            placeholders = ",".join("?" for _ in chunk)
            query = f"""
                SELECT id, title, directory, time_archived
                FROM session
                WHERE id IN ({placeholders})
            """
            for row in connection.execute(query, chunk).fetchall():
                rows_by_id[row["id"]] = dict(row)
        return rows_by_id
    finally:
        connection.close()


def current_session_id_from_args(args: argparse.Namespace) -> str | None:
    candidates = [
        args.current_session_id,
        os.environ.get("OPENCODE_SESSION_ID"),
        os.environ.get("OPENCODE_SESSION"),
    ]
    for candidate in candidates:
        if candidate:
            return candidate
    return None


def build_result(
    *,
    status: str,
    session_id: str,
    row: dict[str, Any] | None = None,
    reason: str | None = None,
    planned_action: str | None = None,
) -> dict[str, Any]:
    result: dict[str, Any] = {
        "id": session_id,
        "status": status,
    }
    if row:
        result["title"] = row.get("title")
        result["directory"] = row.get("directory")
    if reason:
        result["reason"] = reason
    if planned_action:
        result["planned_action"] = planned_action
    return result


def build_plan(
    *,
    manifest: dict[str, Any],
    opencode_home: Path,
    current_session_id: str | None,
) -> tuple[list[dict[str, Any]], dict[str, int]]:
    db_path = opencode_home / "opencode.db"
    if not db_path.exists():
        raise FileNotFoundError(f"database not found: {db_path}")

    session_ids = extract_session_ids(manifest)
    rows_by_id = fetch_sessions(db_path, session_ids)

    results: list[dict[str, Any]] = []
    for session_id in session_ids:
        if current_session_id and session_id == current_session_id:
            results.append(
                build_result(
                    status="skipped_current_session",
                    session_id=session_id,
                    reason="matches current OpenCode session ID",
                )
            )
            continue

        row = rows_by_id.get(session_id)
        if row is None:
            results.append(
                build_result(
                    status="error",
                    session_id=session_id,
                    reason="session not found in opencode.db",
                )
            )
            continue

        if row.get("time_archived") is not None:
            results.append(build_result(status="already_archived", session_id=session_id, row=row))
            continue

        results.append(
            build_result(
                status="archived",
                session_id=session_id,
                row=row,
                planned_action="set_time_archived",
            )
        )

    return results, summarize(results)


def summarize(results: list[dict[str, Any]]) -> dict[str, int]:
    summary = {key: 0 for key in SUMMARY_KEYS}
    for result in results:
        status = result["status"]
        if status == "error":
            summary["errors"] += 1
        elif status in summary:
            summary[status] += 1
    return summary


def backup_database(db_path: Path) -> Path:
    timestamp = dt.datetime.now(tz=dt.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    backup_path = db_path.with_name(f"{db_path.name}.bak-ai-session-coach-{timestamp}")
    source = sqlite3.connect(f"{db_path.as_uri()}?mode=ro", uri=True)
    try:
        destination = sqlite3.connect(str(backup_path))
        try:
            source.backup(destination)
        finally:
            destination.close()
    finally:
        source.close()
    return backup_path


def mark_apply_failure(
    results: list[dict[str, Any]],
    archive_candidates: list[dict[str, Any]],
    reason: str,
) -> None:
    candidate_ids = {candidate["id"] for candidate in archive_candidates}
    for result in results:
        if result["id"] not in candidate_ids:
            continue
        result["status"] = "error"
        result["reason"] = reason


def apply_archive(
    *,
    db_path: Path,
    results: list[dict[str, Any]],
) -> tuple[Path | None, str | None]:
    archive_candidates = [result for result in results if result["status"] == "archived"]
    if not archive_candidates:
        return None, None

    backup_path = backup_database(db_path)
    archived_at_ms = int(dt.datetime.now(tz=dt.timezone.utc).timestamp() * 1000)
    connection = sqlite3.connect(str(db_path))
    try:
        connection.execute("BEGIN")
        for result in archive_candidates:
            if result.get("planned_action") != "set_time_archived":
                raise ArchiveFailure(f"unknown archive action: {result.get('planned_action')}")
            cursor = connection.execute(
                """
                UPDATE session
                SET time_archived = ?
                WHERE id = ?
                  AND time_archived IS NULL
                """,
                (archived_at_ms, result["id"]),
            )
            if cursor.rowcount != 1:
                raise ArchiveFailure(f"session is no longer unarchived: {result['id']}")
        connection.commit()
        return backup_path, None
    except Exception as exc:  # noqa: BLE001 - command-line tool reports all failures.
        connection.rollback()
        reason = str(exc)
        mark_apply_failure(results, archive_candidates, reason)
        return backup_path, reason
    finally:
        connection.close()


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, help="Path to ai-session-coach manifest.json.")
    parser.add_argument("--apply", action="store_true", help="Archive sessions. Without this, only dry-run.")
    parser.add_argument("--opencode-home", help="Override manifest.opencode_home, mainly for temp-copy testing.")
    parser.add_argument("--current-session-id", help="Current OpenCode session ID to skip.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    manifest_path = expand_path(args.manifest)
    manifest = load_manifest(manifest_path)
    opencode_home = expand_path(
        args.opencode_home or manifest.get("opencode_home") or default_opencode_home()
    )
    db_path = opencode_home / "opencode.db"
    current_session_id = current_session_id_from_args(args)

    results, summary = build_plan(
        manifest=manifest,
        opencode_home=opencode_home,
        current_session_id=current_session_id,
    )

    backup_path: Path | None = None
    apply_error: str | None = None
    if args.apply:
        backup_path, apply_error = apply_archive(db_path=db_path, results=results)
        summary = summarize(results)

    output = {
        "mode": "apply" if args.apply else "dry-run",
        "applied": args.apply and apply_error is None,
        "manifest_path": str(manifest_path),
        "snapshot_id": manifest.get("snapshot_id"),
        "opencode_home": str(opencode_home),
        "current_session_id": current_session_id,
        "backup_path": str(backup_path) if backup_path else None,
        "summary": summary,
        "apply_error": apply_error,
        "results": results,
    }

    json.dump(output, sys.stdout, ensure_ascii=False, indent=2 if args.pretty else None)
    sys.stdout.write("\n")
    return 1 if apply_error else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

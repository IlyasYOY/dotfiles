#!/usr/bin/env python3
"""Archive Codex sessions listed in an ai-session-coach snapshot manifest."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import shutil
import sqlite3
import sys
from typing import Any


SUMMARY_KEYS = (
    "archived",
    "skipped_current_thread",
    "already_archived",
    "missing_rollout",
    "errors",
)


class ArchiveFailure(RuntimeError):
    """Raised when an apply operation cannot be completed safely."""


def expand_path(value: str | Path) -> Path:
    return Path(os.path.expanduser(str(value))).resolve()


def is_relative_to(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def load_manifest(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("manifest must be a JSON object")
    return value


def extract_session_targets(manifest: dict[str, Any]) -> list[dict[str, str]]:
    seen: set[str] = set()
    targets: list[dict[str, str]] = []
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
            targets.append({"id": session_id, "category": "analyzed"})

    internal_sessions = manifest.get("internal_sessions", [])
    if not isinstance(internal_sessions, list):
        raise ValueError("manifest.internal_sessions must be a list")
    for session in internal_sessions:
        if not isinstance(session, dict):
            continue
        session_id = session.get("id")
        if not isinstance(session_id, str) or not session_id or session_id in seen:
            continue
        seen.add(session_id)
        targets.append({"id": session_id, "category": "internal"})
    return targets


def extract_session_ids(manifest: dict[str, Any]) -> list[str]:
    return [target["id"] for target in extract_session_targets(manifest)]


def chunked(values: list[str], size: int = 800) -> list[list[str]]:
    return [values[index : index + size] for index in range(0, len(values), size)]


def fetch_threads(db_path: Path, session_ids: list[str]) -> dict[str, dict[str, Any]]:
    if not session_ids:
        return {}

    connection = sqlite3.connect(str(db_path))
    connection.row_factory = sqlite3.Row
    try:
        rows_by_id: dict[str, dict[str, Any]] = {}
        for chunk in chunked(session_ids):
            placeholders = ",".join("?" for _ in chunk)
            query = f"""
                SELECT id, title, cwd, rollout_path, archived
                FROM threads
                WHERE id IN ({placeholders})
            """
            for row in connection.execute(query, chunk).fetchall():
                rows_by_id[row["id"]] = dict(row)
        return rows_by_id
    finally:
        connection.close()


def remap_path(path: str | None, manifest_codex_home: Path, codex_home: Path) -> Path | None:
    if not path:
        return None
    candidate = Path(os.path.expanduser(path))
    if not candidate.is_absolute():
        candidate = manifest_codex_home / candidate
    candidate = candidate.resolve(strict=False)
    if manifest_codex_home != codex_home and is_relative_to(candidate, manifest_codex_home):
        return (codex_home / candidate.relative_to(manifest_codex_home)).resolve(strict=False)
    return candidate


def find_rollout(
    *,
    thread_id: str,
    rollout_path: str | None,
    manifest_codex_home: Path,
    codex_home: Path,
) -> Path | None:
    db_candidate = remap_path(rollout_path, manifest_codex_home, codex_home)
    if db_candidate and db_candidate.exists():
        return db_candidate

    sessions_root = codex_home / "sessions"
    if sessions_root.exists():
        matches = sorted(sessions_root.rglob(f"*{thread_id}.jsonl"))
        if matches:
            return matches[0]

    archived_root = codex_home / "archived_sessions"
    if archived_root.exists():
        matches = sorted(archived_root.rglob(f"*{thread_id}.jsonl"))
        if matches:
            return matches[0]

    return None


def build_result(
    *,
    status: str,
    session_id: str,
    row: dict[str, Any] | None = None,
    reason: str | None = None,
    source: Path | None = None,
    destination: Path | None = None,
    planned_action: str | None = None,
    category: str = "analyzed",
) -> dict[str, Any]:
    result: dict[str, Any] = {
        "id": session_id,
        "category": category,
        "status": status,
    }
    if row:
        result["title"] = row.get("title")
        result["cwd"] = row.get("cwd")
    if reason:
        result["reason"] = reason
    if source:
        result["source"] = str(source)
    if destination:
        result["destination"] = str(destination)
    if planned_action:
        result["planned_action"] = planned_action
    return result


def build_plan(
    *,
    manifest: dict[str, Any],
    codex_home: Path,
    current_thread_id: str | None,
) -> tuple[list[dict[str, Any]], dict[str, int]]:
    manifest_codex_home = expand_path(manifest.get("codex_home") or codex_home)
    db_path = codex_home / "state_5.sqlite"
    if not db_path.exists():
        raise FileNotFoundError(f"state database not found: {db_path}")

    targets = extract_session_targets(manifest)
    session_ids = [target["id"] for target in targets]
    rows_by_id = fetch_threads(db_path, session_ids)
    archived_root = codex_home / "archived_sessions"

    results: list[dict[str, Any]] = []
    for target in targets:
        session_id = target["id"]
        category = target["category"]
        if current_thread_id and session_id == current_thread_id:
            results.append(
                build_result(
                    status="skipped_current_thread",
                    session_id=session_id,
                    reason="matches CODEX_THREAD_ID",
                    category=category,
                )
            )
            continue

        row = rows_by_id.get(session_id)
        if row is None:
            results.append(
                build_result(
                    status="error",
                    session_id=session_id,
                    reason="thread not found in state_5.sqlite",
                    category=category,
                )
            )
            continue

        if bool(row.get("archived")):
            results.append(
                build_result(
                    status="already_archived",
                    session_id=session_id,
                    row=row,
                    category=category,
                )
            )
            continue

        source = find_rollout(
            thread_id=session_id,
            rollout_path=row.get("rollout_path"),
            manifest_codex_home=manifest_codex_home,
            codex_home=codex_home,
        )
        if source is None:
            results.append(
                build_result(
                    status="missing_rollout",
                    session_id=session_id,
                    row=row,
                    reason="rollout file not found",
                    category=category,
                )
            )
            continue

        destination = archived_root / source.name
        source_in_archive = is_relative_to(source.resolve(strict=False), archived_root.resolve(strict=False))
        if source_in_archive:
            planned_action = "update_db_only"
        elif destination.exists():
            results.append(
                build_result(
                    status="error",
                    session_id=session_id,
                    row=row,
                    reason="archive destination already exists",
                    source=source,
                    destination=destination,
                    category=category,
                )
            )
            continue
        else:
            planned_action = "move_rollout_and_update_db"

        results.append(
            build_result(
                status="archived",
                session_id=session_id,
                row=row,
                source=source,
                destination=destination,
                planned_action=planned_action,
                category=category,
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


def summarize_by_category(
    results: list[dict[str, Any]],
) -> dict[str, dict[str, int]]:
    return {
        category: summarize(
            [result for result in results if result.get("category") == category]
        )
        for category in ("analyzed", "internal")
    }


def backup_database(db_path: Path) -> Path:
    timestamp = dt.datetime.now(tz=dt.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    backup_path = db_path.with_name(f"{db_path.name}.bak-ai-session-coach-{timestamp}")
    source = sqlite3.connect(str(db_path))
    try:
        destination = sqlite3.connect(str(backup_path))
        try:
            source.backup(destination)
        finally:
            destination.close()
    finally:
        source.close()
    return backup_path


def restore_moved_files(moved_files: list[tuple[Path, Path]]) -> list[dict[str, str]]:
    errors: list[dict[str, str]] = []
    for destination, source in reversed(moved_files):
        try:
            if destination.exists() and not source.exists():
                source.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(destination), str(source))
        except OSError as exc:
            errors.append(
                {
                    "source": str(source),
                    "destination": str(destination),
                    "error": str(exc),
                }
            )
    return errors


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
    codex_home: Path,
    results: list[dict[str, Any]],
) -> tuple[Path | None, list[dict[str, str]], str | None]:
    archive_candidates = [result for result in results if result["status"] == "archived"]
    if not archive_candidates:
        return None, [], None

    backup_path = backup_database(db_path)
    archived_root = codex_home / "archived_sessions"
    archived_root.mkdir(parents=True, exist_ok=True)

    connection = sqlite3.connect(str(db_path))
    moved_files: list[tuple[Path, Path]] = []
    try:
        connection.execute("BEGIN")
        for result in archive_candidates:
            source = Path(result["source"])
            destination = Path(result["destination"])
            planned_action = result.get("planned_action")

            if planned_action == "move_rollout_and_update_db":
                if not source.exists():
                    raise ArchiveFailure(f"rollout disappeared before move: {source}")
                if destination.exists():
                    raise ArchiveFailure(f"archive destination already exists: {destination}")
                shutil.move(str(source), str(destination))
                moved_files.append((destination, source))
            elif planned_action == "update_db_only":
                if not destination.exists():
                    raise ArchiveFailure(f"archived rollout is missing: {destination}")
            else:
                raise ArchiveFailure(f"unknown archive action: {planned_action}")

            cursor = connection.execute(
                """
                UPDATE threads
                SET archived = 1,
                    archived_at = strftime('%s','now'),
                    rollout_path = ?
                WHERE id = ?
                  AND archived = 0
                """,
                (str(destination), result["id"]),
            )
            if cursor.rowcount != 1:
                raise ArchiveFailure(f"thread is no longer unarchived: {result['id']}")

        connection.commit()
        return backup_path, [], None
    except Exception as exc:  # noqa: BLE001 - command-line tool reports all failures.
        connection.rollback()
        restore_errors = restore_moved_files(moved_files)
        reason = str(exc)
        mark_apply_failure(results, archive_candidates, reason)
        return backup_path, restore_errors, reason
    finally:
        connection.close()


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, help="Path to ai-session-coach manifest.json.")
    parser.add_argument("--apply", action="store_true", help="Archive sessions. Without this, only dry-run.")
    parser.add_argument("--codex-home", help="Override manifest.codex_home, mainly for temp-copy testing.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    manifest_path = expand_path(args.manifest)
    manifest = load_manifest(manifest_path)
    codex_home = expand_path(args.codex_home or manifest.get("codex_home") or os.environ.get("CODEX_HOME", "~/.codex"))
    db_path = codex_home / "state_5.sqlite"
    current_thread_id = os.environ.get("CODEX_THREAD_ID")

    results, summary = build_plan(
        manifest=manifest,
        codex_home=codex_home,
        current_thread_id=current_thread_id,
    )
    category_summary = summarize_by_category(results)

    backup_path: Path | None = None
    restore_errors: list[dict[str, str]] = []
    apply_error: str | None = None
    if args.apply:
        backup_path, restore_errors, apply_error = apply_archive(
            db_path=db_path,
            codex_home=codex_home,
            results=results,
        )
        summary = summarize(results)
        category_summary = summarize_by_category(results)

    output = {
        "mode": "apply" if args.apply else "dry-run",
        "applied": args.apply and apply_error is None,
        "manifest_path": str(manifest_path),
        "snapshot_id": manifest.get("snapshot_id"),
        "codex_home": str(codex_home),
        "current_thread_id": current_thread_id,
        "backup_path": str(backup_path) if backup_path else None,
        "summary": summary,
        "summary_by_category": category_summary,
        "apply_error": apply_error,
        "restore_errors": restore_errors,
        "results": results,
    }

    json.dump(output, sys.stdout, ensure_ascii=False, indent=2 if args.pretty else None)
    sys.stdout.write("\n")
    return 1 if apply_error else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

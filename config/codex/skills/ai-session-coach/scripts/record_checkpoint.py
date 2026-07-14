#!/usr/bin/env python3
"""Record a successful full ai-session-coach snapshot checkpoint."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import sys
import tempfile
from typing import Any


CHECKPOINT_FILENAME = "ai-session-coach-state.json"
CHECKPOINT_VERSION = 1


def expand_path(value: str | Path) -> Path:
    return Path(os.path.expanduser(str(value))).resolve()


def load_json_object(path: Path, *, label: str) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be a JSON object: {path}")
    return value


def parse_timestamp(value: Any, *, label: str) -> dt.datetime:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{label} must be an ISO timestamp")
    parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        raise ValueError(f"{label} must include a timezone")
    return parsed.astimezone(dt.timezone.utc)


def validate_manifest(manifest: dict[str, Any]) -> dt.datetime:
    filters = manifest.get("filters")
    if not isinstance(filters, dict):
        raise ValueError("manifest.filters must be a JSON object")
    if filters.get("incremental") is not True:
        raise ValueError("checkpoint requires an incremental snapshot")
    if filters.get("checkpoint_ignored"):
        raise ValueError("checkpoint cannot advance after --ignore-checkpoint")
    if filters.get("projects"):
        raise ValueError("checkpoint cannot advance after a project-scoped run")
    if filters.get("since") or filters.get("until"):
        raise ValueError("checkpoint cannot advance after a date-scoped run")
    if filters.get("max_sessions") not in (None, 0):
        raise ValueError("checkpoint requires an unlimited session snapshot")
    if filters.get("custom_exclude_thread_ids"):
        raise ValueError("checkpoint cannot advance with custom thread exclusions")
    if filters.get("unarchived") and not filters.get("initial_unarchived_baseline"):
        raise ValueError("checkpoint cannot advance with an explicit archive filter")
    return parse_timestamp(
        manifest.get("snapshot_started_at"),
        label="manifest.snapshot_started_at",
    )


def load_existing_checkpoint(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    checkpoint = load_json_object(path, label="checkpoint")
    if checkpoint.get("version") != CHECKPOINT_VERSION:
        raise ValueError(f"unsupported checkpoint version in {path}")
    parse_timestamp(
        checkpoint.get("sessions_updated_through"),
        label="checkpoint.sessions_updated_through",
    )
    return checkpoint


def build_checkpoint(
    *,
    manifest: dict[str, Any],
    existing: dict[str, Any] | None,
    executed_at: dt.datetime | None = None,
) -> dict[str, Any]:
    checked_through = validate_manifest(manifest)
    if existing:
        previous = parse_timestamp(
            existing.get("sessions_updated_through"),
            label="checkpoint.sessions_updated_through",
        )
        if previous > checked_through:
            raise ValueError("manifest is older than the existing checkpoint")

    completed_at = executed_at or dt.datetime.now(tz=dt.timezone.utc)
    if completed_at.tzinfo is None:
        raise ValueError("executed_at must include a timezone")
    return {
        "version": CHECKPOINT_VERSION,
        "last_execution_at": completed_at.astimezone(dt.timezone.utc).isoformat(),
        "sessions_updated_through": checked_through.isoformat(),
        "snapshot_id": manifest.get("snapshot_id"),
    }


def write_json_atomically(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as handle:
            temporary_path = Path(handle.name)
            json.dump(value, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_path, path)
    finally:
        if temporary_path and temporary_path.exists():
            temporary_path.unlink()


def record_checkpoint(
    *,
    manifest_path: Path,
    checkpoint_path: Path | None = None,
    executed_at: dt.datetime | None = None,
) -> tuple[Path, dict[str, Any]]:
    manifest = load_json_object(manifest_path, label="manifest")
    filters = manifest.get("filters")
    manifest_checkpoint_path = (
        filters.get("checkpoint_path") if isinstance(filters, dict) else None
    )
    codex_home = expand_path(
        manifest.get("codex_home") or os.environ.get("CODEX_HOME", "~/.codex")
    )
    target = checkpoint_path or expand_path(
        manifest_checkpoint_path or codex_home / CHECKPOINT_FILENAME
    )
    existing = load_existing_checkpoint(target)
    checkpoint = build_checkpoint(
        manifest=manifest,
        existing=existing,
        executed_at=executed_at,
    )
    write_json_atomically(target, checkpoint)
    return target, checkpoint


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, help="Path to manifest.json.")
    parser.add_argument(
        "--checkpoint-file",
        help="Override the checkpoint path recorded in the manifest.",
    )
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        path, checkpoint = record_checkpoint(
            manifest_path=expand_path(args.manifest),
            checkpoint_path=(
                expand_path(args.checkpoint_file) if args.checkpoint_file else None
            ),
        )
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    output = {
        "checkpoint_path": str(path),
        "checkpoint": checkpoint,
    }
    json.dump(output, sys.stdout, ensure_ascii=False, indent=2 if args.pretty else None)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

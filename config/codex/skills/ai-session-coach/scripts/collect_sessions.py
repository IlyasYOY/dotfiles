#!/usr/bin/env python3
"""Collect local Codex session data for AI workflow analysis."""

from __future__ import annotations

import argparse
from collections import Counter
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import sqlite3
import sys
from typing import Any


SECRET_PATTERNS = [
    (re.compile(r"sk-[A-Za-z0-9_-]{16,}"), "sk-[REDACTED]"),
    (re.compile(r"github_pat_[A-Za-z0-9_]{16,}"), "github_pat_[REDACTED]"),
    (re.compile(r"gh[pousr]_[A-Za-z0-9_]{16,}"), "gh_[REDACTED]"),
    (re.compile(r"Bearer\s+[A-Za-z0-9._~+/=-]{16,}", re.IGNORECASE), "Bearer [REDACTED]"),
    (
        re.compile(
            r"(?i)\b(api[_-]?key|token|secret|password)\b\s*[:=]\s*['\"]?[^'\"\s,}]+"
        ),
        lambda match: f"{match.group(1)}=[REDACTED]",
    ),
]

ERROR_PATTERNS = [
    re.compile(r"Traceback \(most recent call last\)"),
    re.compile(r"\[ERROR\]"),
    re.compile(r"Operation not permitted"),
    re.compile(r"permission denied", re.IGNORECASE),
]

APPROVAL_REVIEW_PROMPT = (
    "The following is the Codex agent history whose request action you are assessing"
)
MODEL_COMMAND_PATTERN = re.compile(r"^/model(?:\s|$)", re.IGNORECASE)
SESSION_COACH_PATTERNS = (
    re.compile(r"^(?:\$|/)?ai-session-coach(?:\s|$)", re.IGNORECASE),
    re.compile(r"^use \$ai-session-coach(?:\s|$)", re.IGNORECASE),
)
CHECKPOINT_FILENAME = "ai-session-coach-state.json"
CHECKPOINT_VERSION = 1


def redact(text: str) -> str:
    result = text
    for pattern, replacement in SECRET_PATTERNS:
        result = pattern.sub(replacement, result)
    return result


def compact_whitespace(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def truncate(text: Any, limit: int) -> str:
    if text is None:
        return ""
    value = redact(str(text))
    if limit <= 0 or len(value) <= limit:
        return value
    return value[: max(0, limit - 15)].rstrip() + " ... [truncated]"


def iso_from_ms(value: int | None) -> str | None:
    if value is None:
        return None
    return dt.datetime.fromtimestamp(value / 1000, tz=dt.timezone.utc).isoformat()


def parse_bound(value: str | None, *, until: bool = False) -> int | None:
    if not value:
        return None
    raw = value.strip()
    date_only = re.fullmatch(r"\d{4}-\d{2}-\d{2}", raw) is not None
    if date_only:
        parsed = dt.datetime.fromisoformat(raw)
        if until:
            parsed = parsed + dt.timedelta(days=1)
    else:
        parsed = dt.datetime.fromisoformat(raw.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        parsed = parsed.astimezone()
    return int(parsed.timestamp() * 1000)


def parse_checkpoint_timestamp(value: Any) -> int:
    if not isinstance(value, str) or not value.strip():
        raise ValueError("checkpoint sessions_updated_through must be an ISO timestamp")
    parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        raise ValueError("checkpoint sessions_updated_through must include a timezone")
    return int(parsed.timestamp() * 1000)


def load_checkpoint(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"checkpoint must be a JSON object: {path}")
    if value.get("version") != CHECKPOINT_VERSION:
        raise ValueError(f"unsupported checkpoint version in {path}")
    parse_checkpoint_timestamp(value.get("sessions_updated_through"))
    return value


def load_threads(codex_home: Path, since_ms: int | None, until_ms: int | None) -> list[dict[str, Any]]:
    db_path = codex_home / "state_5.sqlite"
    if not db_path.exists():
        raise FileNotFoundError(f"state database not found: {db_path}")

    query = """
        SELECT
            id,
            rollout_path,
            COALESCE(created_at_ms, created_at * 1000) AS created_ms,
            COALESCE(updated_at_ms, updated_at * 1000) AS updated_ms,
            source,
            model_provider,
            cwd,
            title,
            sandbox_policy,
            approval_mode,
            tokens_used,
            archived,
            archived_at,
            git_sha,
            git_branch,
            git_origin_url,
            cli_version,
            first_user_message,
            model,
            reasoning_effort,
            thread_source
        FROM threads
        WHERE (? IS NULL OR COALESCE(updated_at_ms, updated_at * 1000) >= ?)
          AND (? IS NULL OR COALESCE(created_at_ms, created_at * 1000) < ?)
        ORDER BY updated_ms DESC, id DESC
    """
    connection = sqlite3.connect(str(db_path))
    connection.row_factory = sqlite3.Row
    try:
        rows = connection.execute(query, (since_ms, since_ms, until_ms, until_ms)).fetchall()
    finally:
        connection.close()
    return [dict(row) for row in rows]


def exclude_threads(rows: list[dict[str, Any]], thread_ids: set[str]) -> list[dict[str, Any]]:
    if not thread_ids:
        return rows
    return [row for row in rows if row.get("id") not in thread_ids]


def internal_session_reason(row: dict[str, Any]) -> str | None:
    thread_source = compact_whitespace(str(row.get("thread_source") or "user")).lower()
    if thread_source != "user":
        return "codex_subagent"

    prompt_candidates = (
        compact_whitespace(str(row.get("first_user_message") or "")),
        compact_whitespace(str(row.get("title") or "")),
    )
    if any(prompt.startswith(APPROVAL_REVIEW_PROMPT) for prompt in prompt_candidates):
        return "approval_review_prompt"
    if any(MODEL_COMMAND_PATTERN.match(prompt) for prompt in prompt_candidates):
        return "model_switch"
    if any(
        pattern.match(prompt)
        for prompt in prompt_candidates
        for pattern in SESSION_COACH_PATTERNS
    ):
        return "session_coach_housekeeping"
    return None


def partition_internal_sessions(
    rows: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    user_rows: list[dict[str, Any]] = []
    internal_rows: list[dict[str, Any]] = []
    for row in rows:
        reason = internal_session_reason(row)
        if reason is None:
            user_rows.append(row)
            continue
        internal_row = dict(row)
        internal_row["internal_reason"] = reason
        internal_rows.append(internal_row)
    return user_rows, internal_rows


def internal_session_summary(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": row.get("id"),
        "source": "codex",
        "project": row.get("cwd") or "",
        "timestamp": iso_from_ms(row.get("created_ms")),
        "reason": row.get("internal_reason"),
    }


def normalize_project(value: str) -> dict[str, Any]:
    expanded = os.path.expanduser(value)
    path_like = os.path.isabs(expanded) or os.sep in expanded
    if path_like:
        return {"kind": "path", "raw": value, "path": str(Path(expanded).resolve())}
    return {"kind": "name", "raw": value, "name": value.lower()}


def cwd_matches(cwd: str, projects: list[dict[str, Any]]) -> bool:
    if not projects:
        return True
    if not cwd:
        return False
    cwd_path = Path(cwd).resolve()
    cwd_text = str(cwd_path)
    parts = {part.lower() for part in cwd_path.parts}
    for project in projects:
        if project["kind"] == "path":
            project_path = project["path"]
            if cwd_text == project_path or cwd_text.startswith(project_path + os.sep):
                return True
        elif project["name"] in parts:
            return True
    return False


def limit_rows(rows: list[dict[str, Any]], max_sessions: int | None) -> list[dict[str, Any]]:
    if max_sessions is None or max_sessions <= 0:
        return rows
    return rows[:max_sessions]


def flatten_content(content: Any) -> str:
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, dict):
                if isinstance(item.get("text"), str):
                    parts.append(item["text"])
                elif isinstance(item.get("message"), str):
                    parts.append(item["message"])
                elif isinstance(item.get("summary"), str):
                    parts.append(item["summary"])
            elif item is not None:
                parts.append(str(item))
        return "\n".join(part for part in parts if part)
    if isinstance(content, dict):
        for key in ("text", "message", "summary"):
            if isinstance(content.get(key), str):
                return content[key]
    return str(content)


def parse_arguments(value: Any) -> Any:
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value
    return value


def extract_commands(arguments: Any) -> list[str]:
    commands: list[str] = []
    if isinstance(arguments, dict):
        cmd = arguments.get("cmd")
        if isinstance(cmd, str):
            commands.append(cmd)
        for key in ("tool_uses", "calls"):
            nested = arguments.get(key)
            if isinstance(nested, list):
                for item in nested:
                    commands.extend(extract_commands(item))
        params = arguments.get("parameters")
        if isinstance(params, dict):
            commands.extend(extract_commands(params))
    elif isinstance(arguments, list):
        for item in arguments:
            commands.extend(extract_commands(item))
    return commands


def summarize_arguments(arguments: Any, limit: int) -> str:
    if isinstance(arguments, (dict, list)):
        return truncate(json.dumps(arguments, ensure_ascii=False, sort_keys=True), limit)
    return truncate(arguments, limit)


def output_exit_code(output: str) -> int | None:
    match = re.search(r"Process exited with code ([0-9]+)", output)
    if not match:
        return None
    return int(match.group(1))


def output_body(output: str) -> str:
    match = re.search(r"\nOutput:\n(.*)\Z", output, re.DOTALL)
    if not match:
        return output.strip()
    return match.group(1).strip()


def expected_empty_status_one(commands: list[str], output: str) -> bool:
    if output_exit_code(output) != 1 or output_body(output):
        return False
    prefixes = ("rg ", "command -v ")
    return any(command.strip().startswith(prefixes) for command in commands)


def looks_like_failure(output: str, commands: list[str] | None = None) -> bool:
    command_list = commands or []
    if expected_empty_status_one(command_list, output):
        return False
    code = output_exit_code(output)
    if code is not None:
        return code != 0
    return any(pattern.search(output) for pattern in ERROR_PATTERNS)


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            if not line.strip():
                continue
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError as exc:
                entries.append(
                    {
                        "type": "parse_error",
                        "timestamp": None,
                        "payload": {"line": line_number, "error": str(exc)},
                    }
                )
    return entries


def parse_rollout(
    path: Path,
    *,
    max_message_chars: int,
    max_output_chars: int,
    max_events_per_session: int,
    include_tool_outputs: bool,
) -> dict[str, Any]:
    messages: list[dict[str, Any]] = []
    agent_updates: list[dict[str, Any]] = []
    tool_calls: list[dict[str, Any]] = []
    command_failures: list[dict[str, Any]] = []
    approval_requests: list[dict[str, Any]] = []
    summaries: list[str] = []
    final_outcome = ""
    calls_by_id: dict[str, dict[str, Any]] = {}
    seen_messages: set[tuple[str, str]] = set()

    try:
        entries = read_jsonl(path)
    except OSError as exc:
        return {"rollout_read_error": str(exc)}

    for entry in entries:
        entry_type = entry.get("type")
        payload = entry.get("payload") or {}
        timestamp = entry.get("timestamp")

        if entry_type == "turn_context":
            summary = flatten_content(payload.get("summary"))
            if summary:
                summaries.append(truncate(summary, max_message_chars))
            continue

        if entry_type == "event_msg":
            event_type = payload.get("type")
            if event_type == "user_message":
                text = payload.get("message") or flatten_content(payload.get("text_elements"))
                message_key = ("user", compact_whitespace(text)[:240])
                if text and message_key not in seen_messages and len(messages) < max_events_per_session:
                    seen_messages.add(message_key)
                    messages.append(
                        {
                            "timestamp": timestamp,
                            "role": "user",
                            "source": "event_msg",
                            "text": truncate(text, max_message_chars),
                        }
                    )
            elif event_type == "agent_message":
                text = payload.get("message")
                if text and len(agent_updates) < max_events_per_session:
                    agent_updates.append(
                        {
                            "timestamp": timestamp,
                            "phase": payload.get("phase"),
                            "text": truncate(text, max_message_chars),
                        }
                    )
            elif event_type == "task_complete":
                final_outcome = truncate(payload.get("message") or payload.get("info") or "task_complete", max_message_chars)
            continue

        if entry_type != "response_item":
            continue

        item_type = payload.get("type")
        if item_type == "message":
            role = payload.get("role")
            text = flatten_content(payload.get("content"))
            message_key = (str(role), compact_whitespace(text)[:240])
            if role in {"user", "assistant"} and text and message_key not in seen_messages and len(messages) < max_events_per_session:
                seen_messages.add(message_key)
                messages.append(
                    {
                        "timestamp": timestamp,
                        "role": role,
                        "source": "response_item",
                        "text": truncate(text, max_message_chars),
                    }
                )
                if role == "assistant":
                    final_outcome = truncate(text, max_message_chars)
        elif item_type == "reasoning":
            summary = flatten_content(payload.get("summary") or payload.get("content"))
            if summary:
                summaries.append(truncate(summary, max_message_chars))
        elif item_type == "function_call":
            arguments = parse_arguments(payload.get("arguments"))
            commands = extract_commands(arguments)
            call = {
                "timestamp": timestamp,
                "call_id": payload.get("call_id"),
                "name": payload.get("name"),
                "commands": [truncate(command, max_message_chars) for command in commands],
                "arguments": summarize_arguments(arguments, max_message_chars),
            }
            if isinstance(arguments, dict):
                if arguments.get("sandbox_permissions") == "require_escalated":
                    call["requires_approval"] = True
                    approval_requests.append(
                        {
                            "timestamp": timestamp,
                            "tool": payload.get("name"),
                            "justification": truncate(arguments.get("justification", ""), max_message_chars),
                            "commands": call["commands"],
                        }
                    )
            if len(tool_calls) < max_events_per_session:
                tool_calls.append(call)
            if payload.get("call_id"):
                calls_by_id[payload["call_id"]] = call
        elif item_type == "function_call_output":
            output = str(payload.get("output", ""))
            call = calls_by_id.get(payload.get("call_id"), {})
            commands = call.get("commands", [])
            if looks_like_failure(output, commands):
                failure = {
                    "timestamp": timestamp,
                    "tool": call.get("name"),
                    "commands": commands,
                    "exit_code": output_exit_code(output),
                    "output": truncate(output, max_output_chars),
                }
                command_failures.append(failure)
            elif include_tool_outputs and len(tool_calls) <= max_events_per_session:
                call = calls_by_id.get(payload.get("call_id"))
                if call is not None:
                    call["output_excerpt"] = truncate(output, max_output_chars)

    return {
        "messages": messages,
        "agent_updates": agent_updates,
        "tool_calls": tool_calls,
        "command_failures": command_failures,
        "approval_requests": approval_requests,
        "summaries": summaries[:max_events_per_session],
        "final_outcome": final_outcome,
    }


def find_agents_files(cwds: list[str], max_chars: int) -> list[dict[str, Any]]:
    seen: set[Path] = set()
    results: list[dict[str, Any]] = []
    for cwd in cwds:
        if not cwd:
            continue
        current = Path(cwd).resolve()
        for _ in range(8):
            candidate = current / "AGENTS.md"
            if candidate in seen:
                pass
            elif candidate.exists():
                seen.add(candidate)
                try:
                    excerpt = candidate.read_text(encoding="utf-8", errors="replace")
                except OSError as exc:
                    excerpt = f"[read error: {exc}]"
                results.append(
                    {
                        "path": str(candidate),
                        "excerpt": truncate(excerpt, max_chars),
                    }
                )
            parent = current.parent
            if parent == current:
                break
            current = parent
    return results


def resolve_rollout_path(row: dict[str, Any], codex_home: Path) -> tuple[Path | None, str | None]:
    rollout_path = Path(row["rollout_path"]) if row.get("rollout_path") else None
    if rollout_path and rollout_path.exists():
        return rollout_path, "state_5.sqlite"

    thread_id = row.get("id")
    if not thread_id:
        return rollout_path, None

    for root_name in ("sessions", "archived_sessions"):
        root = codex_home / root_name
        if not root.exists():
            continue
        matches = sorted(root.rglob(f"*{thread_id}.jsonl"))
        if matches:
            return matches[0], root_name

    return rollout_path, None


def build_session(
    row: dict[str, Any],
    *,
    codex_home: Path,
    max_message_chars: int,
    max_output_chars: int,
    max_events_per_session: int,
    include_tool_outputs: bool,
) -> dict[str, Any]:
    rollout_path, rollout_path_source = resolve_rollout_path(row, codex_home)
    parsed: dict[str, Any] = {}
    missing_rollout = False
    if rollout_path and rollout_path.exists():
        parsed = parse_rollout(
            rollout_path,
            max_message_chars=max_message_chars,
            max_output_chars=max_output_chars,
            max_events_per_session=max_events_per_session,
            include_tool_outputs=include_tool_outputs,
        )
    else:
        missing_rollout = True

    session = {
        "id": row.get("id"),
        "title": row.get("title"),
        "cwd": row.get("cwd"),
        "created_at": iso_from_ms(row.get("created_ms")),
        "updated_at": iso_from_ms(row.get("updated_ms")),
        "rollout_path": str(rollout_path) if rollout_path else None,
        "rollout_path_source": rollout_path_source,
        "missing_rollout": missing_rollout,
        "archived": bool(row.get("archived")),
        "git_branch": row.get("git_branch"),
        "model": row.get("model"),
        "reasoning_effort": row.get("reasoning_effort"),
        "tokens_used": row.get("tokens_used"),
        "approval_mode": row.get("approval_mode"),
        "sandbox_policy": row.get("sandbox_policy"),
        "first_user_message": truncate(row.get("first_user_message", ""), max_message_chars),
    }
    session.update(parsed)
    return session


def group_sessions_by_cwd(sessions: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    groups: dict[str, list[dict[str, Any]]] = {}
    for session in sessions:
        cwd = session.get("cwd") or ""
        groups.setdefault(cwd, []).append(session)
    return dict(
        sorted(
            groups.items(),
            key=lambda item: (-len(item[1]), item[0]),
        )
    )


def safe_project_filename(index: int, cwd: str) -> str:
    label = Path(cwd).name if cwd else "unknown"
    label = re.sub(r"[^a-z0-9._-]+", "-", label.lower()).strip("-._")
    if not label:
        label = "project"
    digest = hashlib.sha256(cwd.encode("utf-8")).hexdigest()[:10]
    return f"project-{index:03d}-{label}-{digest}.json"


def make_project_summaries(
    grouped_sessions: dict[str, list[dict[str, Any]]],
    project_files: dict[str, str] | None = None,
) -> list[dict[str, Any]]:
    summaries: list[dict[str, Any]] = []
    for cwd, sessions in grouped_sessions.items():
        updated_values = [session.get("updated_at") for session in sessions if session.get("updated_at")]
        created_values = [session.get("created_at") for session in sessions if session.get("created_at")]
        summary = {
            "cwd": cwd,
            "session_count": len(sessions),
            "session_ids": [session.get("id") for session in sessions],
            "created_at_min": min(created_values) if created_values else None,
            "created_at_max": max(created_values) if created_values else None,
            "updated_at_min": min(updated_values) if updated_values else None,
            "updated_at_max": max(updated_values) if updated_values else None,
        }
        if project_files:
            summary["project_file"] = project_files[cwd]
        summaries.append(summary)
    return summaries


def build_filters(
    args: argparse.Namespace,
    *,
    since_ms: int | None,
    until_ms: int | None,
    max_sessions: int | None,
    excluded_thread_ids: set[str],
    current_thread_id: str | None,
    checkpoint_path: Path,
    checkpoint: dict[str, Any] | None,
    checkpoint_ignored: bool,
    effective_since_ms: int | None,
    initial_unarchived_baseline: bool,
) -> dict[str, Any]:
    return {
        "projects": args.project,
        "since": args.since,
        "until": args.until,
        "since_ms": since_ms,
        "effective_since_ms": effective_since_ms,
        "until_ms_exclusive": until_ms,
        "unarchived": args.unarchived,
        "incremental": args.incremental,
        "checkpoint_path": str(checkpoint_path),
        "checkpoint_exists": checkpoint is not None,
        "checkpoint_ignored": checkpoint_ignored,
        "checkpoint_sessions_updated_through": (
            checkpoint.get("sessions_updated_through") if checkpoint else None
        ),
        "initial_unarchived_baseline": initial_unarchived_baseline,
        "exclude_current_thread": args.exclude_current_thread,
        "current_thread_id": current_thread_id,
        "custom_exclude_thread_ids": sorted(
            thread_id for thread_id in args.exclude_thread if thread_id
        ),
        "exclude_thread_ids": sorted(excluded_thread_ids),
        "include_internal": args.include_internal,
        "max_sessions": max_sessions,
    }


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_analysis_packs(
    *,
    out_dir: Path,
    snapshot_started_at: str,
    generated_at: str,
    codex_home: Path,
    filters: dict[str, Any],
    counts: dict[str, Any],
    analysis_focus: str,
    grouped_sessions: dict[str, list[dict[str, Any]]],
    internal_sessions: list[dict[str, Any]],
    max_agents_chars: int,
) -> dict[str, Any]:
    out_dir.mkdir(parents=True, exist_ok=True)

    project_files = {
        cwd: safe_project_filename(index, cwd)
        for index, cwd in enumerate(grouped_sessions.keys(), start=1)
    }

    projects: list[dict[str, Any]] = []
    for cwd, sessions in grouped_sessions.items():
        project_file = project_files[cwd]
        existing_project_instructions = find_agents_files([cwd], max_agents_chars)
        project_pack = {
            "generated_at": generated_at,
            "codex_home": str(codex_home),
            "analysis_focus": analysis_focus,
            "project": {
                "cwd": cwd,
                "session_count": len(sessions),
                "session_ids": [session.get("id") for session in sessions],
            },
            "filters": filters,
            "existing_project_instructions": existing_project_instructions,
            "sessions": sessions,
        }
        write_json(out_dir / project_file, project_pack)

        project_summary = make_project_summaries({cwd: sessions}, project_files)[0]
        project_summary["existing_project_instructions_count"] = len(existing_project_instructions)
        projects.append(project_summary)

    session_ids = [
        str(session.get("id"))
        for sessions in grouped_sessions.values()
        for session in sessions
        if session.get("id")
    ]
    snapshot_session_ids = session_ids + [
        str(session.get("id"))
        for session in internal_sessions
        if session.get("id")
    ]
    snapshot_hash = hashlib.sha256(
        "\n".join(snapshot_session_ids).encode("utf-8")
    ).hexdigest()[:12]
    snapshot_id = f"{generated_at.replace(':', '').replace('-', '').replace('.', '')}-{snapshot_hash}"
    manifest = {
        "snapshot_started_at": snapshot_started_at,
        "generated_at": generated_at,
        "snapshot_id": snapshot_id,
        "codex_home": str(codex_home),
        "analysis_focus": analysis_focus,
        "filters": filters,
        "counts": counts,
        "projects": projects,
        "internal_sessions": internal_sessions,
        "read_only": True,
        "notes": "This snapshot is for analysis only. It does not archive, update, move, or delete Codex sessions.",
    }
    write_json(out_dir / "manifest.json", manifest)
    return manifest


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", action="append", default=[], help="Project path or simple project name. Repeatable.")
    parser.add_argument("--since", help="Start date/time. Date-only values use local midnight.")
    parser.add_argument("--until", help="End date/time. Date-only values include that whole local day.")
    parser.add_argument("--codex-home", default=os.environ.get("CODEX_HOME", "~/.codex"), help="Codex home directory.")
    parser.add_argument("--unarchived", action="store_true", help="Only include sessions with archived = 0.")
    parser.add_argument(
        "--incremental",
        action="store_true",
        help="Use the saved coach checkpoint; without one, include unarchived sessions as the migration baseline.",
    )
    parser.add_argument(
        "--checkpoint-file",
        help="Override the default <codex-home>/ai-session-coach-state.json checkpoint.",
    )
    parser.add_argument(
        "--ignore-checkpoint",
        action="store_true",
        help="Ignore saved checkpoint filtering for an intentional historical rerun.",
    )
    parser.add_argument("--exclude-current-thread", action="store_true", help="Exclude CODEX_THREAD_ID when it is set.")
    parser.add_argument("--exclude-thread", action="append", default=[], help="Thread ID to exclude. Repeatable.")
    parser.add_argument(
        "--include-internal",
        action="store_true",
        help="Include subagents, approval reviews, coach housekeeping, and model-switch sessions.",
    )
    parser.add_argument("--out-dir", help="Write manifest.json and per-project JSON analysis packs to this directory.")
    parser.add_argument("--analysis-focus", default="", help="User request or analysis focus copied into generated packs.")
    parser.add_argument(
        "--max-sessions",
        type=int,
        default=None,
        help="Maximum matched sessions to load. Defaults to all for incremental or --unarchived, otherwise 40. Use 0 for unlimited.",
    )
    parser.add_argument("--max-message-chars", type=int, default=900, help="Maximum chars per message/snippet.")
    parser.add_argument("--max-output-chars", type=int, default=900, help="Maximum chars per tool output snippet.")
    parser.add_argument("--max-events-per-session", type=int, default=80, help="Maximum messages/tool calls per session.")
    parser.add_argument("--no-tool-outputs", action="store_true", help="Skip non-failing tool output excerpts.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    codex_home = Path(os.path.expanduser(args.codex_home)).resolve()
    checkpoint_path = Path(
        os.path.expanduser(
            args.checkpoint_file or str(codex_home / CHECKPOINT_FILENAME)
        )
    ).resolve()
    if args.ignore_checkpoint and not args.incremental:
        raise ValueError("--ignore-checkpoint requires --incremental")
    checkpoint = (
        None
        if args.ignore_checkpoint or not args.incremental
        else load_checkpoint(checkpoint_path)
    )
    since_ms = parse_bound(args.since)
    until_ms = parse_bound(args.until, until=True)
    checkpoint_since_ms = (
        parse_checkpoint_timestamp(checkpoint["sessions_updated_through"])
        if checkpoint
        else None
    )
    effective_since_ms = since_ms
    if checkpoint_since_ms is not None:
        effective_since_ms = max(
            value for value in (since_ms, checkpoint_since_ms) if value is not None
        )
    initial_unarchived_baseline = (
        args.incremental and checkpoint is None and not args.ignore_checkpoint
    )
    projects = [normalize_project(project) for project in args.project]
    max_sessions = args.max_sessions
    if max_sessions is None:
        max_sessions = 0 if args.incremental or args.unarchived else 40

    excluded_thread_ids = {thread_id for thread_id in args.exclude_thread if thread_id}
    current_thread_id = None
    if args.exclude_current_thread:
        current_thread_id = os.environ.get("CODEX_THREAD_ID")
        if current_thread_id:
            excluded_thread_ids.add(current_thread_id)

    snapshot_started_at = dt.datetime.now(tz=dt.timezone.utc).isoformat()
    rows = load_threads(codex_home, effective_since_ms, until_ms)
    use_unarchived_filter = args.unarchived or initial_unarchived_baseline
    incrementally_filtered_rows = (
        [row for row in rows if not bool(row.get("archived"))]
        if use_unarchived_filter
        else rows
    )
    eligible_rows = exclude_threads(incrementally_filtered_rows, excluded_thread_ids)
    matched_rows = [row for row in eligible_rows if cwd_matches(row.get("cwd", ""), projects)]
    user_rows, internal_rows = partition_internal_sessions(matched_rows)
    analysis_rows = matched_rows if args.include_internal else user_rows
    excluded_internal_rows = [] if args.include_internal else internal_rows
    limited_rows = limit_rows(analysis_rows, max_sessions)

    sessions = [
        build_session(
            row,
            codex_home=codex_home,
            max_message_chars=args.max_message_chars,
            max_output_chars=args.max_output_chars,
            max_events_per_session=args.max_events_per_session,
            include_tool_outputs=not args.no_tool_outputs,
        )
        for row in limited_rows
    ]

    cwds = sorted({session.get("cwd", "") for session in sessions if session.get("cwd")})
    grouped_sessions = group_sessions_by_cwd(sessions)
    internal_sessions = [
        internal_session_summary(row) for row in excluded_internal_rows
    ]
    internal_reasons = Counter(
        str(row.get("internal_reason")) for row in excluded_internal_rows
    )
    generated_at = dt.datetime.now(tz=dt.timezone.utc).isoformat()
    filters = build_filters(
        args,
        since_ms=since_ms,
        until_ms=until_ms,
        max_sessions=max_sessions,
        excluded_thread_ids=excluded_thread_ids,
        current_thread_id=current_thread_id,
        checkpoint_path=checkpoint_path,
        checkpoint=checkpoint,
        checkpoint_ignored=args.ignore_checkpoint,
        effective_since_ms=effective_since_ms,
        initial_unarchived_baseline=initial_unarchived_baseline,
    )
    counts = {
        "candidate_sessions_after_time_filter": len(rows),
        "sessions_after_incremental_filter": len(incrementally_filtered_rows),
        "excluded_sessions": (
            len(incrementally_filtered_rows)
            - len(eligible_rows)
            + len(excluded_internal_rows)
        ),
        "explicitly_excluded_sessions": (
            len(incrementally_filtered_rows) - len(eligible_rows)
        ),
        "internal_sessions_excluded": len(excluded_internal_rows),
        "internal_exclusion_reasons": dict(sorted(internal_reasons.items())),
        "matched_sessions": len(matched_rows),
        "loaded_sessions": len(sessions),
        "projects": len(grouped_sessions),
        "missing_rollouts": sum(1 for session in sessions if session.get("missing_rollout")),
    }

    if args.out_dir:
        out_dir = Path(os.path.expanduser(args.out_dir)).resolve()
        manifest = write_analysis_packs(
            out_dir=out_dir,
            snapshot_started_at=snapshot_started_at,
            generated_at=generated_at,
            codex_home=codex_home,
            filters=filters,
            counts=counts,
            analysis_focus=args.analysis_focus,
            grouped_sessions=grouped_sessions,
            internal_sessions=internal_sessions,
            max_agents_chars=args.max_output_chars * 2,
        )
        output = {
            "manifest_path": str(out_dir / "manifest.json"),
            "project_pack_count": len(manifest["projects"]),
            "counts": counts,
            "read_only": True,
        }
        json.dump(output, sys.stdout, ensure_ascii=False, indent=2 if args.pretty else None)
        sys.stdout.write("\n")
        return 0

    output = {
        "generated_at": generated_at,
        "codex_home": str(codex_home),
        "analysis_focus": args.analysis_focus,
        "filters": filters,
        "counts": counts,
        "projects": make_project_summaries(grouped_sessions),
        "existing_project_instructions": find_agents_files(cwds, args.max_output_chars * 2),
        "sessions": sessions,
        "internal_sessions": internal_sessions,
    }

    json.dump(output, sys.stdout, ensure_ascii=False, indent=2 if args.pretty else None)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

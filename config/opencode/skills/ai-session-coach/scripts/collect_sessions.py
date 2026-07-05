#!/usr/bin/env python3
"""Collect local OpenCode session data for AI workflow analysis."""

from __future__ import annotations

import argparse
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
    (
        re.compile(r"Bearer\s+[A-Za-z0-9._~+/=-]{16,}", re.IGNORECASE),
        "Bearer [REDACTED]",
    ),
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

LOG_LINE_RE = re.compile(r'([\w.]+)=((?:"(?:[^"\\]|\\.)*")|[^\s]+)')
LOG_SESSION_RE = re.compile(r"session\.id=([^\s]+)")


def redact(text: str) -> str:
    result = text
    for pattern, replacement in SECRET_PATTERNS:
        result = pattern.sub(replacement, result)
    return result


def truncate(value: Any, limit: int) -> str:
    text = "" if value is None else redact(str(value))
    if limit <= 0 or len(text) <= limit:
        return text
    return text[: max(0, limit - 15)].rstrip() + " ... [truncated]"


def compact_whitespace(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


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


def parse_json(value: Any) -> Any:
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value
    return value


def stringify(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    try:
        return json.dumps(value, ensure_ascii=False, sort_keys=True)
    except TypeError:
        return str(value)


def parse_log_kv(line: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for match in LOG_LINE_RE.finditer(line):
        key = match.group(1)
        value = match.group(2)
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
        result[key] = value
    return result


def flatten_content(content: Any) -> str:
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, dict):
                for key in ("text", "message", "summary", "content"):
                    if isinstance(item.get(key), str):
                        parts.append(item[key])
                        break
            elif item is not None:
                parts.append(str(item))
        return "\n".join(part for part in parts if part)
    if isinstance(content, dict):
        for key in ("text", "message", "summary", "content"):
            if isinstance(content.get(key), str):
                return content[key]
    return str(content)


def summarize_arguments(arguments: Any, limit: int) -> str:
    if isinstance(arguments, (dict, list)):
        return truncate(json.dumps(arguments, ensure_ascii=False, sort_keys=True), limit)
    return truncate(arguments, limit)


def output_exit_code(output: str) -> int | None:
    match = re.search(r"Process exited with code ([0-9]+)", output)
    if match:
        return int(match.group(1))
    return None


def output_body(output: str) -> str:
    match = re.search(r"\nOutput:\n(.*)\Z", output, re.DOTALL)
    if not match:
        return output.strip()
    return match.group(1).strip()


def tool_exit_code(state: dict[str, Any], output: str) -> int | None:
    metadata = state.get("metadata")
    if isinstance(metadata, dict) and isinstance(metadata.get("exit"), int):
        return metadata["exit"]
    return output_exit_code(output)


def expected_empty_status_one(
    commands: list[str], output: str, exit_code: int | None
) -> bool:
    if exit_code != 1 or output_body(output):
        return False
    return any(
        command.strip().startswith(("rg ", "command -v ")) for command in commands
    )


def looks_like_failure(
    output: str,
    commands: list[str] | None = None,
    *,
    exit_code: int | None = None,
    status: str | None = None,
) -> bool:
    command_list = commands or []
    if expected_empty_status_one(command_list, output, exit_code):
        return False
    if exit_code is not None:
        return exit_code != 0
    if status in {"error", "failed"}:
        return True
    return any(pattern.search(output) for pattern in ERROR_PATTERNS)


def append_message(
    messages: list[dict[str, Any]],
    seen_messages: set[tuple[str, str]],
    *,
    role: str,
    timestamp: str | None,
    source: str,
    text: str,
    max_message_chars: int,
    max_events: int,
) -> None:
    key = (role, compact_whitespace(text)[:240])
    if not text or key in seen_messages or len(messages) >= max_events:
        return
    seen_messages.add(key)
    messages.append(
        {
            "timestamp": timestamp,
            "role": role,
            "source": source,
            "text": truncate(text, max_message_chars),
        }
    )


def model_from_json(value: Any) -> str:
    if isinstance(value, dict):
        provider = value.get("providerID", "")
        model = value.get("id", "") or value.get("modelID", "")
        if provider and model:
            return f"{provider}/{model}"
        return model or str(value)
    return str(value) if value else ""


def default_opencode_home() -> str:
    data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
    return os.environ.get("OPENCODE_HOME", os.path.join(data_home, "opencode"))


def connect_state(opencode_home: Path) -> sqlite3.Connection:
    db_path = opencode_home / "opencode.db"
    if not db_path.exists():
        raise FileNotFoundError(f"database not found: {db_path}")
    connection = sqlite3.connect(f"{db_path.as_uri()}?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    return connection


def load_sessions(
    connection: sqlite3.Connection, since_ms: int | None, until_ms: int | None
) -> list[dict[str, Any]]:
    query = """
        SELECT
            id, project_id, workspace_id, parent_id, slug,
            directory, path, title, version,
            summary_additions, summary_deletions, summary_files,
            summary_diffs, metadata,
            cost, tokens_input, tokens_output, tokens_reasoning,
            tokens_cache_read, tokens_cache_write,
            permission, agent, model, revert,
            time_created, time_updated, time_compacting, time_archived
        FROM session
        WHERE (? IS NULL OR time_updated >= ?)
          AND (? IS NULL OR time_created < ?)
        ORDER BY time_updated DESC, id DESC
    """
    rows = connection.execute(
        query, (since_ms, since_ms, until_ms, until_ms)
    ).fetchall()
    return [dict(row) for row in rows]


def exclude_sessions(rows: list[dict[str, Any]], session_ids: set[str]) -> list[dict[str, Any]]:
    if not session_ids:
        return rows
    return [row for row in rows if row.get("id") not in session_ids]


def normalize_project(value: str) -> dict[str, Any]:
    expanded = os.path.expanduser(value)
    path_like = os.path.isabs(expanded) or os.sep in expanded
    if path_like:
        return {"kind": "path", "raw": value, "path": str(Path(expanded).resolve())}
    return {"kind": "name", "raw": value, "name": value.lower()}


def directory_matches(directory: str, projects: list[dict[str, Any]]) -> bool:
    if not projects:
        return True
    if not directory:
        return False
    directory_path = Path(directory).resolve()
    directory_text = str(directory_path)
    parts = {part.lower() for part in directory_path.parts}
    for project in projects:
        if project["kind"] == "path":
            project_path = project["path"]
            if directory_text == project_path or directory_text.startswith(
                project_path + os.sep
            ):
                return True
        elif project["name"] in parts:
            return True
    return False


def limit_rows(rows: list[dict[str, Any]], max_sessions: int | None) -> list[dict[str, Any]]:
    if max_sessions is None or max_sessions <= 0:
        return rows
    return rows[:max_sessions]


def parse_session_messages(
    connection: sqlite3.Connection,
    session_id: str,
    *,
    max_message_chars: int,
    max_output_chars: int,
    max_events: int,
    include_tool_outputs: bool,
) -> dict[str, Any]:
    messages: list[dict[str, Any]] = []
    tool_calls: list[dict[str, Any]] = []
    command_failures: list[dict[str, Any]] = []
    approval_requests: list[dict[str, Any]] = []
    summaries: list[str] = []
    final_outcome = ""
    seen_messages: set[tuple[str, str]] = set()
    model_switches: list[dict[str, Any]] = []
    agent_switches: list[dict[str, Any]] = []

    model_query = """
        SELECT sm.type, sm.time_created, sm.data
        FROM session_message sm
        WHERE sm.session_id = ?
        ORDER BY sm.seq
    """
    for row in connection.execute(model_query, (session_id,)):
        data = parse_json(row["data"])
        if not isinstance(data, dict):
            continue
        if row["type"] == "model-switched":
            model_switches.append(
                {
                    "timestamp": iso_from_ms(row["time_created"]),
                    "model": model_from_json(data.get("model")),
                }
            )
        elif row["type"] == "agent-switched":
            agent_switches.append(
                {
                    "timestamp": iso_from_ms(row["time_created"]),
                    "agent": data.get("agent", ""),
                }
            )

    msgs_query = """
        SELECT m.id, m.data, m.time_created
        FROM message m
        WHERE m.session_id = ?
        ORDER BY m.time_created, m.id
    """
    for msg_row in connection.execute(msgs_query, (session_id,)):
        msg_data = parse_json(msg_row["data"])
        if not isinstance(msg_data, dict):
            continue
        role = msg_data.get("role", "")

        parts_query = """
            SELECT p.data, p.time_created
            FROM part p
            WHERE p.message_id = ?
            ORDER BY p.time_created, p.id
        """
        for part_row in connection.execute(parts_query, (msg_row["id"],)):
            part_data = parse_json(part_row["data"])
            if not isinstance(part_data, dict):
                continue
            part_type = part_data.get("type", "")
            part_ts = iso_from_ms(part_row["time_created"])

            if part_type == "text":
                text = part_data.get("text", "")
                if role == "user":
                    append_message(
                        messages,
                        seen_messages,
                        role="user",
                        timestamp=part_ts,
                        source="message-part",
                        text=text,
                        max_message_chars=max_message_chars,
                        max_events=max_events,
                    )
                elif role == "assistant":
                    append_message(
                        messages,
                        seen_messages,
                        role="assistant",
                        timestamp=part_ts,
                        source="message-part",
                        text=text,
                        max_message_chars=max_message_chars,
                        max_events=max_events,
                    )
                    if text:
                        final_outcome = truncate(text, max_message_chars)

            elif part_type == "reasoning":
                reasoning_text = flatten_content(part_data.get("text"))
                if reasoning_text and len(summaries) < max_events:
                    summaries.append(truncate(reasoning_text, max_message_chars))

            elif part_type == "tool":
                tool_name = str(part_data.get("tool", ""))
                state = part_data.get("state")
                state = state if isinstance(state, dict) else {}
                tool_input = state.get("input")
                tool_input = tool_input if isinstance(tool_input, dict) else {}
                output_str = stringify(state.get("output"))
                status = state.get("status") if isinstance(state.get("status"), str) else None
                exit_code = tool_exit_code(state, output_str)
                command = tool_input.get("command") if isinstance(tool_input.get("command"), str) else ""
                commands = [command] if command else []

                display_name = tool_name
                if tool_name == "task":
                    subagent = tool_input.get("subagent_type", "")
                    display_name = f"task({subagent})" if subagent else "task"

                call = {
                    "timestamp": part_ts,
                    "call_id": part_data.get("callID"),
                    "name": display_name,
                    "commands": [truncate(cmd, max_message_chars) for cmd in commands],
                    "arguments": summarize_arguments(tool_input, max_message_chars),
                }
                if include_tool_outputs and output_str:
                    call["output_excerpt"] = truncate(output_str, max_output_chars)
                if len(tool_calls) < max_events:
                    tool_calls.append(call)

                if tool_name == "bash" and looks_like_failure(
                    output_str, commands, exit_code=exit_code, status=status
                ):
                    command_failures.append(
                        {
                            "timestamp": part_ts,
                            "tool": tool_name,
                            "commands": [
                                truncate(command_value, max_message_chars)
                                for command_value in commands
                            ],
                            "exit_code": exit_code,
                            "output": truncate(output_str, max_output_chars),
                        }
                    )

                if tool_name == "question" and len(approval_requests) < max_events:
                    approval_requests.append(
                        {
                            "timestamp": part_ts,
                            "tool": tool_name,
                            "arguments": summarize_arguments(tool_input, max_message_chars),
                        }
                    )

    return {
        "messages": messages,
        "tool_calls": tool_calls,
        "command_failures": command_failures,
        "approval_requests": approval_requests,
        "summaries": summaries,
        "final_outcome": final_outcome,
        "model_switches": model_switches,
        "agent_switches": agent_switches,
    }


def empty_log_data() -> dict[str, Any]:
    return {
        "permission_stats": {},
        "approval_requests": [],
        "log_errors": [],
        "log_lines_scanned": 0,
    }


def parse_log_for_sessions(
    log_path: Path,
    session_ids: set[str],
    *,
    max_output_chars: int,
    max_events_per_session: int,
) -> dict[str, dict[str, Any]]:
    results = {session_id: empty_log_data() for session_id in session_ids}
    if not log_path.exists() or not session_ids:
        return results

    try:
        with log_path.open("r", encoding="utf-8") as handle:
            for line in handle:
                match = LOG_SESSION_RE.search(line)
                if not match:
                    continue
                session_id = match.group(1)
                if session_id not in results:
                    continue

                data = results[session_id]
                data["log_lines_scanned"] += 1
                parsed = parse_log_kv(line)
                message = parsed.get("message", "")

                if message == "evaluated":
                    permission = parsed.get("permission", "")
                    action = parsed.get("action.action", "")
                    key = f"{permission}:{action}"
                    stats = data["permission_stats"]
                    stats[key] = stats.get(key, 0) + 1
                elif message == "asking":
                    approval_requests = data["approval_requests"]
                    if len(approval_requests) < max_events_per_session:
                        approval_requests.append(
                            {
                                "permission": parsed.get("permission", ""),
                                "raw": truncate(line.strip(), max_output_chars),
                            }
                        )

                level = parsed.get("level", "")
                if level in {"ERROR", "WARN"}:
                    log_errors = data["log_errors"]
                    if len(log_errors) < max_events_per_session:
                        log_errors.append(
                            {
                                "timestamp": parsed.get("timestamp", ""),
                                "level": level,
                                "message": message,
                                "raw": truncate(line.strip(), max_output_chars),
                            }
                        )
    except OSError:
        pass

    return results


def load_todos(
    connection: sqlite3.Connection,
    session_id: str,
    *,
    max_events: int,
) -> list[dict[str, Any]]:
    todos: list[dict[str, Any]] = []
    query = """
        SELECT content, status, priority, position, time_created
        FROM todo
        WHERE session_id = ?
        ORDER BY position
    """
    for row in connection.execute(query, (session_id,)):
        if len(todos) >= max_events:
            break
        todos.append(
            {
                "content": truncate(row["content"], 500),
                "status": row["status"],
                "priority": row["priority"],
                "position": row["position"],
                "time_created": iso_from_ms(row["time_created"]),
            }
        )
    return todos


def load_session_diff_summary(
    opencode_home: Path,
    session_id: str,
    *,
    max_output_chars: int,
) -> dict[str, Any] | None:
    diff_path = opencode_home / "storage" / "session_diff" / f"{session_id}.json"
    if not diff_path.exists():
        return None
    try:
        value = json.loads(diff_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {
            "path": str(diff_path),
            "available": True,
            "read_error": True,
        }
    return {
        "path": str(diff_path),
        "available": True,
        "excerpt": truncate(json.dumps(value, ensure_ascii=False), max_output_chars),
    }


def find_agents_files(directories: list[str], max_chars: int) -> list[dict[str, Any]]:
    seen: set[Path] = set()
    results: list[dict[str, Any]] = []
    for directory in directories:
        if not directory:
            continue
        current = Path(directory).resolve()
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


def build_session(
    row: dict[str, Any],
    *,
    connection: sqlite3.Connection,
    opencode_home: Path,
    log_data: dict[str, Any],
    max_message_chars: int,
    max_output_chars: int,
    max_events_per_session: int,
    include_tool_outputs: bool,
) -> dict[str, Any]:
    session_id = row["id"]
    parsed = parse_session_messages(
        connection,
        session_id,
        max_message_chars=max_message_chars,
        max_output_chars=max_output_chars,
        max_events=max_events_per_session,
        include_tool_outputs=include_tool_outputs,
    )
    todos = load_todos(connection, session_id, max_events=max_events_per_session)
    model_val = parse_json(row.get("model"))
    session = {
        "id": session_id,
        "title": truncate(row.get("title"), max_message_chars),
        "directory": row.get("directory"),
        "created_at": iso_from_ms(row.get("time_created")),
        "updated_at": iso_from_ms(row.get("time_updated")),
        "archived": row.get("time_archived") is not None,
        "time_archived": iso_from_ms(row.get("time_archived")),
        "model": model_from_json(model_val),
        "agent": parse_json(row.get("agent")),
        "permission": parse_json(row.get("permission")),
        "tokens_input": row.get("tokens_input"),
        "tokens_output": row.get("tokens_output"),
        "tokens_reasoning": row.get("tokens_reasoning"),
        "tokens_cache_read": row.get("tokens_cache_read"),
        "tokens_cache_write": row.get("tokens_cache_write"),
        "cost": row.get("cost"),
        "summary_additions": row.get("summary_additions"),
        "summary_deletions": row.get("summary_deletions"),
        "summary_files": row.get("summary_files"),
        "parent_id": row.get("parent_id"),
        "version": row.get("version"),
        "todos": todos,
        "log": log_data,
        "session_diff": load_session_diff_summary(
            opencode_home, session_id, max_output_chars=max_output_chars
        ),
    }
    session.update(parsed)
    return session


def group_sessions_by_directory(
    sessions: list[dict[str, Any]],
) -> dict[str, list[dict[str, Any]]]:
    groups: dict[str, list[dict[str, Any]]] = {}
    for session in sessions:
        directory = session.get("directory") or ""
        groups.setdefault(directory, []).append(session)
    return dict(sorted(groups.items(), key=lambda item: (-len(item[1]), item[0])))


def safe_project_filename(index: int, directory: str) -> str:
    label = Path(directory).name if directory else "unknown"
    label = re.sub(r"[^a-z0-9._-]+", "-", label.lower()).strip("-._")
    if not label:
        label = "project"
    digest = hashlib.sha256(directory.encode("utf-8")).hexdigest()[:10]
    return f"project-{index:03d}-{label}-{digest}.json"


def make_project_summaries(
    grouped_sessions: dict[str, list[dict[str, Any]]],
    project_files: dict[str, str] | None = None,
) -> list[dict[str, Any]]:
    summaries: list[dict[str, Any]] = []
    for directory, sessions in grouped_sessions.items():
        updated_values = [session.get("updated_at") for session in sessions if session.get("updated_at")]
        created_values = [session.get("created_at") for session in sessions if session.get("created_at")]
        summary = {
            "directory": directory,
            "session_count": len(sessions),
            "session_ids": [session.get("id") for session in sessions],
            "created_at_min": min(created_values) if created_values else None,
            "created_at_max": max(created_values) if created_values else None,
            "updated_at_min": min(updated_values) if updated_values else None,
            "updated_at_max": max(updated_values) if updated_values else None,
        }
        if project_files:
            summary["project_file"] = project_files[directory]
        summaries.append(summary)
    return summaries


def build_filters(
    args: argparse.Namespace,
    *,
    since_ms: int | None,
    until_ms: int | None,
    max_sessions: int | None,
    excluded_session_ids: set[str],
    current_session_id: str | None,
) -> dict[str, Any]:
    return {
        "projects": args.project,
        "since": args.since,
        "until": args.until,
        "since_ms": since_ms,
        "until_ms_exclusive": until_ms,
        "unarchived": args.unarchived,
        "exclude_current_session": args.exclude_current_session,
        "current_session_id": current_session_id,
        "exclude_session_ids": sorted(excluded_session_ids),
        "max_sessions": max_sessions,
    }


def write_json(path: Path, value: dict[str, Any]) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_analysis_packs(
    *,
    out_dir: Path,
    generated_at: str,
    opencode_home: Path,
    filters: dict[str, Any],
    counts: dict[str, Any],
    analysis_focus: str,
    grouped_sessions: dict[str, list[dict[str, Any]]],
    max_agents_chars: int,
) -> dict[str, Any]:
    out_dir.mkdir(parents=True, exist_ok=True)

    project_files = {
        directory: safe_project_filename(index, directory)
        for index, directory in enumerate(grouped_sessions.keys(), start=1)
    }

    projects: list[dict[str, Any]] = []
    for directory, sessions in grouped_sessions.items():
        project_file = project_files[directory]
        existing_project_instructions = find_agents_files([directory], max_agents_chars)
        project_pack = {
            "generated_at": generated_at,
            "opencode_home": str(opencode_home),
            "analysis_focus": analysis_focus,
            "project": {
                "directory": directory,
                "session_count": len(sessions),
                "session_ids": [session.get("id") for session in sessions],
            },
            "filters": filters,
            "existing_project_instructions": existing_project_instructions,
            "sessions": sessions,
        }
        write_json(out_dir / project_file, project_pack)

        project_summary = make_project_summaries({directory: sessions}, project_files)[0]
        project_summary["existing_project_instructions_count"] = len(existing_project_instructions)
        projects.append(project_summary)

    session_ids = [
        str(session.get("id"))
        for sessions in grouped_sessions.values()
        for session in sessions
        if session.get("id")
    ]
    snapshot_hash = hashlib.sha256("\n".join(session_ids).encode("utf-8")).hexdigest()[:12]
    snapshot_id = f"{generated_at.replace(':', '').replace('-', '').replace('.', '')}-{snapshot_hash}"
    manifest = {
        "generated_at": generated_at,
        "snapshot_id": snapshot_id,
        "opencode_home": str(opencode_home),
        "analysis_focus": analysis_focus,
        "filters": filters,
        "counts": counts,
        "projects": projects,
        "read_only": True,
        "notes": "This snapshot is for analysis only. It does not archive, update, move, or delete OpenCode sessions.",
    }
    write_json(out_dir / "manifest.json", manifest)
    return manifest


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


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", action="append", default=[], help="Project path or simple project name. Repeatable.")
    parser.add_argument("--since", help="Start date/time. Date-only values use local midnight.")
    parser.add_argument("--until", help="End date/time. Date-only values include that whole local day.")
    parser.add_argument("--opencode-home", default=default_opencode_home(), help="OpenCode data directory.")
    parser.add_argument("--unarchived", action="store_true", help="Only include sessions with time_archived IS NULL.")
    parser.add_argument("--exclude-current-session", action="store_true", help="Exclude the current OpenCode session when its ID is available.")
    parser.add_argument("--current-session-id", help="Current OpenCode session ID to exclude when --exclude-current-session is set.")
    parser.add_argument("--exclude-session", action="append", default=[], help="Session ID to exclude. Repeatable.")
    parser.add_argument("--out-dir", help="Write manifest.json and per-project JSON analysis packs to this directory.")
    parser.add_argument("--analysis-focus", default="", help="User request or analysis focus copied into generated packs.")
    parser.add_argument(
        "--max-sessions",
        type=int,
        default=None,
        help="Maximum matched sessions to load. Defaults to all for --unarchived, otherwise 40. Use 0 for unlimited.",
    )
    parser.add_argument("--max-message-chars", type=int, default=900, help="Maximum chars per message/snippet.")
    parser.add_argument("--max-output-chars", type=int, default=900, help="Maximum chars per tool output snippet.")
    parser.add_argument("--max-events-per-session", type=int, default=80, help="Maximum messages/tool calls per session.")
    parser.add_argument("--no-tool-outputs", action="store_true", help="Skip non-failing tool output excerpts.")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON.")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    opencode_home = Path(os.path.expanduser(args.opencode_home)).resolve()
    since_ms = parse_bound(args.since)
    until_ms = parse_bound(args.until, until=True)
    projects = [normalize_project(project) for project in args.project]
    max_sessions = args.max_sessions
    if max_sessions is None:
        max_sessions = 0 if args.unarchived else 40

    excluded_session_ids = {session_id for session_id in args.exclude_session if session_id}
    current_session_id = current_session_id_from_args(args)
    if args.exclude_current_session:
        if current_session_id:
            excluded_session_ids.add(current_session_id)

    with connect_state(opencode_home) as connection:
        rows = load_sessions(connection, since_ms, until_ms)
        archive_filtered_rows = [
            row for row in rows if row.get("time_archived") is None
        ] if args.unarchived else rows
        eligible_rows = exclude_sessions(archive_filtered_rows, excluded_session_ids)
        matched_rows = [
            row for row in eligible_rows if directory_matches(row.get("directory", ""), projects)
        ]
        limited_rows = limit_rows(matched_rows, max_sessions)

        session_ids = {str(row["id"]) for row in limited_rows if row.get("id")}
        logs_by_session = parse_log_for_sessions(
            opencode_home / "log" / "opencode.log",
            session_ids,
            max_output_chars=args.max_output_chars,
            max_events_per_session=args.max_events_per_session,
        )
        sessions = [
            build_session(
                row,
                connection=connection,
                opencode_home=opencode_home,
                log_data=logs_by_session.get(str(row["id"]), empty_log_data()),
                max_message_chars=args.max_message_chars,
                max_output_chars=args.max_output_chars,
                max_events_per_session=args.max_events_per_session,
                include_tool_outputs=not args.no_tool_outputs,
            )
            for row in limited_rows
        ]

    directories = sorted({session.get("directory", "") for session in sessions if session.get("directory")})
    grouped_sessions = group_sessions_by_directory(sessions)
    generated_at = dt.datetime.now(tz=dt.timezone.utc).isoformat()
    filters = build_filters(
        args,
        since_ms=since_ms,
        until_ms=until_ms,
        max_sessions=max_sessions,
        excluded_session_ids=excluded_session_ids,
        current_session_id=current_session_id,
    )
    counts = {
        "candidate_sessions_in_time_window": len(rows),
        "sessions_after_archive_filter": len(archive_filtered_rows),
        "excluded_sessions": len(archive_filtered_rows) - len(eligible_rows),
        "matched_sessions": len(matched_rows),
        "loaded_sessions": len(sessions),
        "projects": len(grouped_sessions),
    }

    if args.out_dir:
        out_dir = Path(os.path.expanduser(args.out_dir)).resolve()
        manifest = write_analysis_packs(
            out_dir=out_dir,
            generated_at=generated_at,
            opencode_home=opencode_home,
            filters=filters,
            counts=counts,
            analysis_focus=args.analysis_focus,
            grouped_sessions=grouped_sessions,
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
        "opencode_home": str(opencode_home),
        "analysis_focus": args.analysis_focus,
        "filters": filters,
        "counts": counts,
        "projects": make_project_summaries(grouped_sessions),
        "existing_project_instructions": find_agents_files(directories, args.max_output_chars * 2),
        "sessions": sessions,
    }

    json.dump(output, sys.stdout, ensure_ascii=False, indent=2 if args.pretty else None)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

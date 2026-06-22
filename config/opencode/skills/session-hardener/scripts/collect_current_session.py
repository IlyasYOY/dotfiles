#!/usr/bin/env python3
"""Collect bounded, redacted evidence from one local OpenCode session."""

from __future__ import annotations

import argparse
import datetime as dt
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

LOG_LINE_RE = re.compile(r"([\w.]+)=("
    r'"(?:[^"\\]|\\.)*"'
    r"|"
    r"[^\s]+"
    r")")

LOG_PERMISSION_RE = re.compile(
    r"permission=(\w+).*?pattern=\"(.*?)\".*?action\.action=(\w+)"
)

LOG_ASKING_RE = re.compile(
    r"asking.*?permission=(\w+).*?patterns=\[(.*?)\]"
)


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


def parse_json(value: Any) -> Any:
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value
    return value


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
        return "\n".join(parts)
    if isinstance(content, dict):
        for key in ("text", "message", "summary", "content"):
            if isinstance(content.get(key), str):
                return content[key]
    return str(content)


def extract_commands(arguments: Any) -> list[str]:
    commands: list[str] = []
    if isinstance(arguments, dict):
        cmd = arguments.get("cmd")
        if isinstance(cmd, str):
            commands.append(cmd)
        for key in ("tool_uses", "calls", "command"):
            nested = arguments.get(key)
            if isinstance(nested, list):
                for item in nested:
                    commands.extend(extract_commands(item))
        params = arguments.get("parameters")
        if isinstance(params, dict):
            commands.extend(extract_commands(params))
        input_data = arguments.get("input")
        if isinstance(input_data, dict):
            commands.extend(extract_commands(input_data))
    elif isinstance(arguments, list):
        for item in arguments:
            commands.extend(extract_commands(item))
    return commands


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
    return any(
        command.strip().startswith(("rg ", "command -v "))
        for command in commands
    )


def looks_like_failure(output: str, commands: list[str] | None = None) -> bool:
    command_list = commands or []
    if expected_empty_status_one(command_list, output):
        return False
    code = output_exit_code(output)
    if code is not None:
        return code != 0
    return any(pattern.search(output) for pattern in ERROR_PATTERNS)


def connect_state(opencode_home: Path) -> sqlite3.Connection:
    db_path = opencode_home / "opencode.db"
    if not db_path.exists():
        raise FileNotFoundError(f"database not found: {db_path}")
    connection = sqlite3.connect(str(db_path))
    connection.row_factory = sqlite3.Row
    return connection


def load_session_by_id(
    connection: sqlite3.Connection, session_id: str
) -> dict[str, Any]:
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
        WHERE id = ?
    """
    row = connection.execute(query, (session_id,)).fetchone()
    if row is None:
        raise LookupError(f"session not found: {session_id}")
    return dict(row)


def load_latest_for_cwd(
    connection: sqlite3.Connection, cwd: Path
) -> dict[str, Any]:
    target = cwd.resolve()
    sessions_query = """
        SELECT
            s.id, s.project_id, s.workspace_id, s.parent_id, s.slug,
            s.directory, s.path, s.title, s.version,
            s.summary_additions, s.summary_deletions, s.summary_files,
            s.summary_diffs, s.metadata,
            s.cost, s.tokens_input, s.tokens_output, s.tokens_reasoning,
            s.tokens_cache_read, s.tokens_cache_write,
            s.permission, s.agent, s.model, s.revert,
            s.time_created, s.time_updated, s.time_compacting, s.time_archived
        FROM session s
        JOIN project p ON s.project_id = p.id
        WHERE s.directory IS NOT NULL
        ORDER BY s.time_updated DESC, s.id DESC
    """
    for row in connection.execute(sessions_query):
        row_dict = dict(row)
        value = row_dict.get("directory")
        if not value:
            continue
        candidate = Path(value).resolve()
        if candidate == target or str(candidate).startswith(
            str(target) + os.sep
        ):
            return row_dict
    raise LookupError(f"no OpenCode session found for cwd: {target}")


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


def parse_session_messages(
    connection: sqlite3.Connection,
    session_id: str,
    *,
    max_message_chars: int,
    max_output_chars: int,
    max_events: int,
) -> dict[str, Any]:
    messages: list[dict[str, Any]] = []
    tool_calls: list[dict[str, Any]] = []
    command_failures: list[dict[str, Any]] = []
    approval_requests: list[dict[str, Any]] = []
    summaries: list[str] = []
    final_outcome = ""
    seen_messages: set[tuple[str, str]] = set()
    calls_by_id: dict[str, dict[str, Any]] = {}
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
        if row["type"] == "model-switched":
            model_switches.append({
                "timestamp": iso_from_ms(row["time_created"]),
                "model": model_from_json(data.get("model")),
            })
        elif row["type"] == "agent-switched":
            agent_switches.append({
                "timestamp": iso_from_ms(row["time_created"]),
                "agent": data.get("agent", ""),
            })

    msgs_query = """
        SELECT m.id, m.data, m.time_created
        FROM message m
        WHERE m.session_id = ?
        ORDER BY m.time_created, m.id
    """
    for msg_row in connection.execute(msgs_query, (session_id,)):
        msg_data = parse_json(msg_row["data"])
        role = msg_data.get("role", "")
        timestamp = iso_from_ms(msg_row["time_created"])

        parts_query = """
            SELECT p.data, p.time_created
            FROM part p
            WHERE p.message_id = ?
            ORDER BY p.time_created, p.id
        """
        part_rows = list(connection.execute(parts_query, (msg_row["id"],)))

        for part_row in part_rows:
            part_data = parse_json(part_row["data"])
            part_type = part_data.get("type", "")
            part_ts = iso_from_ms(part_row["time_created"])

            if part_type == "text":
                text = part_data.get("text", "")
                if role == "user":
                    append_message(
                        messages, seen_messages,
                        role="user", timestamp=part_ts,
                        source="message-part", text=text,
                        max_message_chars=max_message_chars,
                        max_events=max_events,
                    )
                elif role == "assistant":
                    append_message(
                        messages, seen_messages,
                        role="assistant", timestamp=part_ts,
                        source="message-part", text=text,
                        max_message_chars=max_message_chars,
                        max_events=max_events,
                    )
                    if text:
                        final_outcome = truncate(text, max_message_chars)

            elif part_type == "reasoning":
                reasoning_text = part_data.get("text", "")
                if reasoning_text and len(summaries) < max_events:
                    summaries.append(truncate(
                        reasoning_text, max_message_chars
                    ))

            elif part_type == "tool":
                tool_name = part_data.get("tool", "")
                call_id = part_data.get("callID", "")
                state = part_data.get("state", {})
                tool_input = state.get("input", {})
                tool_output = state.get("output", "")

                if tool_name == "bash":
                    description = tool_input.get("description", "")
                    command = tool_input.get("command", "")
                    commands_list = [command] if command else []

                    call = {
                        "timestamp": part_ts,
                        "call_id": call_id,
                        "name": tool_name,
                        "commands": [
                            truncate(c, max_message_chars)
                            for c in commands_list
                        ],
                        "arguments": truncate(
                            json.dumps(tool_input, ensure_ascii=False, sort_keys=True),
                            max_message_chars,
                        ),
                    }
                    if len(tool_calls) < max_events:
                        tool_calls.append(call)
                    if call_id:
                        calls_by_id[call_id] = call

                    if command:
                        output_str = str(tool_output) if tool_output else ""
                        if looks_like_failure(output_str, commands_list):
                            command_failures.append({
                                "timestamp": part_ts,
                                "tool": tool_name,
                                "commands": [
                                    truncate(c, max_message_chars)
                                    for c in commands_list
                                ],
                                "exit_code": output_exit_code(output_str),
                                "output": truncate(
                                    output_str, max_output_chars
                                ),
                            })

                elif tool_name == "task":
                    subagent = tool_input.get("subagent_type", "")
                    call = {
                        "timestamp": part_ts,
                        "call_id": call_id,
                        "name": f"task({subagent})",
                        "commands": [],
                        "arguments": truncate(
                            json.dumps(tool_input, ensure_ascii=False, sort_keys=True),
                            max_message_chars,
                        ),
                    }
                    if len(tool_calls) < max_events:
                        tool_calls.append(call)
                    if call_id:
                        calls_by_id[call_id] = call

                elif tool_name in ("question", "todowrite"):
                    call = {
                        "timestamp": part_ts,
                        "call_id": call_id,
                        "name": tool_name,
                        "commands": [],
                        "arguments": truncate(
                            json.dumps(tool_input, ensure_ascii=False, sort_keys=True),
                            max_message_chars,
                        ),
                    }
                    if len(tool_calls) < max_events:
                        tool_calls.append(call)

                else:
                    call = {
                        "timestamp": part_ts,
                        "call_id": call_id,
                        "name": tool_name,
                        "commands": [],
                        "arguments": truncate(
                            json.dumps(tool_input, ensure_ascii=False, sort_keys=True),
                            max_message_chars,
                        ),
                    }
                    if len(tool_calls) < max_events:
                        tool_calls.append(call)

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


def parse_log_for_session(
    log_path: Path,
    session_id: str,
    *,
    max_message_chars: int,
    max_output_chars: int,
    max_events: int,
) -> dict[str, Any]:
    permission_stats: dict[str, int] = {}
    approval_requests: list[dict[str, Any]] = []
    log_errors: list[dict[str, Any]] = []

    if not log_path.exists():
        return {
            "permission_stats": permission_stats,
            "approval_requests": approval_requests,
            "log_errors": log_errors,
            "log_lines_scanned": 0,
        }

    session_prefix = f"session.id={session_id}"
    lines_scanned = 0
    try:
        with log_path.open("r", encoding="utf-8") as handle:
            for line in handle:
                lines_scanned += 1
                if session_prefix not in line:
                    continue

                parsed = parse_log_kv(line)
                message = parsed.get("message", "")

                if message == "evaluated":
                    permission = parsed.get("permission", "")
                    action_action = parsed.get("action.action", "")
                    key = f"{permission}:{action_action}"
                    permission_stats[key] = permission_stats.get(key, 0) + 1

                elif message == "asking":
                    permission = parsed.get("permission", "")
                    if len(approval_requests) < max_events:
                        approval_requests.append({
                            "permission": permission,
                            "raw": truncate(line.strip(), max_output_chars),
                        })

                level = parsed.get("level", "")
                if level in ("ERROR", "WARN"):
                    if len(log_errors) < max_events:
                        log_errors.append({
                            "timestamp": parsed.get("timestamp", ""),
                            "level": level,
                            "message": message,
                            "raw": truncate(line.strip(), max_output_chars),
                        })
    except OSError:
        pass

    return {
        "permission_stats": permission_stats,
        "approval_requests": approval_requests,
        "log_errors": log_errors,
        "log_lines_scanned": lines_scanned,
    }


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
        todos.append({
            "content": row["content"],
            "status": row["status"],
            "priority": row["priority"],
            "position": row["position"],
            "time_created": iso_from_ms(row["time_created"]),
        })
    return todos


def load_session_diff(
    opencode_home: Path, session_id: str
) -> dict[str, Any] | None:
    diff_path = opencode_home / "storage" / "session_diff" / f"{session_id}.json"
    if not diff_path.exists():
        return None
    try:
        return json.loads(diff_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None


def build_output(
    *,
    row: dict[str, Any],
    opencode_home: Path,
    source: str,
    parsed: dict[str, Any],
    todos: list[dict[str, Any]],
    log_data: dict[str, Any],
    diff_data: dict[str, Any] | None,
    args: argparse.Namespace,
) -> dict[str, Any]:
    model_val = parse_json(row.get("model"))
    return {
        "read_only": True,
        "generated_at": dt.datetime.now(tz=dt.timezone.utc).isoformat(),
        "opencode_home": str(opencode_home),
        "source": source,
        "limits": {
            "max_message_chars": args.max_message_chars,
            "max_output_chars": args.max_output_chars,
            "max_events": args.max_events,
        },
        "session": {
            "id": row.get("id"),
            "title": truncate(row.get("title"), args.max_message_chars),
            "directory": row.get("directory"),
            "created_at": iso_from_ms(row.get("time_created")),
            "updated_at": iso_from_ms(row.get("time_updated")),
            "model": model_from_json(model_val),
            "agent": parse_json(row.get("agent")),
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
        },
        "messages": parsed.get("messages", []),
        "tool_calls": parsed.get("tool_calls", []),
        "command_failures": parsed.get("command_failures", []),
        "approval_requests": parsed.get("approval_requests", []),
        "summaries": parsed.get("summaries", []),
        "final_outcome": parsed.get("final_outcome", ""),
        "model_switches": parsed.get("model_switches", []),
        "agent_switches": parsed.get("agent_switches", []),
        "todos": todos,
        "log": log_data,
        "session_diff": diff_data,
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session-id")
    parser.add_argument(
        "--latest-for-cwd",
        help="Fallback: inspect the latest session whose directory is "
             "this path or a descendant.",
    )
    parser.add_argument(
        "--opencode-home",
        default=os.environ.get(
            "XDG_DATA_HOME",
            os.path.expanduser("~/.local/share"),
        ) + "/opencode",
        help="OpenCode data directory.",
    )
    parser.add_argument("--max-message-chars", type=int, default=1200)
    parser.add_argument("--max-output-chars", type=int, default=1200)
    parser.add_argument("--max-events", type=int, default=120)
    parser.add_argument("--pretty", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    opencode_home = Path(os.path.expanduser(args.opencode_home)).resolve()

    try:
        with connect_state(opencode_home) as connection:
            if args.session_id:
                row = load_session_by_id(connection, args.session_id)
                source = "session-id"
            elif args.latest_for_cwd:
                row = load_latest_for_cwd(
                    connection, Path(args.latest_for_cwd)
                )
                source = "latest-for-cwd"
            else:
                raise ValueError(
                    "no session id available; pass --session-id "
                    "or --latest-for-cwd"
                )

            session_id = row["id"]
            parsed = parse_session_messages(
                connection,
                session_id,
                max_message_chars=args.max_message_chars,
                max_output_chars=args.max_output_chars,
                max_events=args.max_events,
            )
            todos = load_todos(
                connection, session_id, max_events=args.max_events
            )

        log_path = opencode_home / "log" / "opencode.log"
        log_data = parse_log_for_session(
            log_path,
            session_id,
            max_message_chars=args.max_message_chars,
            max_output_chars=args.max_output_chars,
            max_events=args.max_events,
        )
        diff_data = load_session_diff(opencode_home, session_id)

        output = build_output(
            row=row,
            opencode_home=opencode_home,
            source=source,
            parsed=parsed,
            todos=todos,
            log_data=log_data,
            diff_data=diff_data,
            args=args,
        )
        json.dump(
            output,
            sys.stdout,
            ensure_ascii=False,
            indent=2 if args.pretty else None,
        )
        sys.stdout.write("\n")
        return 0
    except (FileNotFoundError, LookupError, OSError, sqlite3.Error, ValueError) as exc:
        json.dump(
            {"read_only": True, "error": str(exc)},
            sys.stderr,
            ensure_ascii=False,
            indent=2 if args.pretty else None,
        )
        sys.stderr.write("\n")
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

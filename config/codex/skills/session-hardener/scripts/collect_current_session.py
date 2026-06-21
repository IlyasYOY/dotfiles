#!/usr/bin/env python3
"""Collect bounded, redacted evidence from one local Codex session."""

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


def parse_arguments(value: Any) -> Any:
    if isinstance(value, str):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value
    return value


def flatten_content(content: Any) -> str:
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, dict):
                for key in ("text", "message", "summary"):
                    if isinstance(item.get(key), str):
                        parts.append(item[key])
                        break
            elif item is not None:
                parts.append(str(item))
        return "\n".join(parts)
    if isinstance(content, dict):
        for key in ("text", "message", "summary"):
            if isinstance(content.get(key), str):
                return content[key]
    return str(content)


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
    return any(command.strip().startswith(("rg ", "command -v ")) for command in commands)


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


def connect_state(codex_home: Path) -> sqlite3.Connection:
    db_path = codex_home / "state_5.sqlite"
    if not db_path.exists():
        raise FileNotFoundError(f"state database not found: {db_path}")
    connection = sqlite3.connect(str(db_path))
    connection.row_factory = sqlite3.Row
    return connection


def load_thread_by_id(connection: sqlite3.Connection, thread_id: str) -> dict[str, Any]:
    query = """
        SELECT
            id,
            rollout_path,
            COALESCE(created_at_ms, created_at * 1000) AS created_ms,
            COALESCE(updated_at_ms, updated_at * 1000) AS updated_ms,
            cwd,
            title,
            sandbox_policy,
            approval_mode,
            tokens_used,
            archived,
            git_sha,
            git_branch,
            model,
            reasoning_effort,
            first_user_message
        FROM threads
        WHERE id = ?
    """
    row = connection.execute(query, (thread_id,)).fetchone()
    if row is None:
        raise LookupError(f"thread not found in state database: {thread_id}")
    return dict(row)


def load_latest_for_cwd(connection: sqlite3.Connection, cwd: Path) -> dict[str, Any]:
    query = """
        SELECT
            id,
            rollout_path,
            COALESCE(created_at_ms, created_at * 1000) AS created_ms,
            COALESCE(updated_at_ms, updated_at * 1000) AS updated_ms,
            cwd,
            title,
            sandbox_policy,
            approval_mode,
            tokens_used,
            archived,
            git_sha,
            git_branch,
            model,
            reasoning_effort,
            first_user_message
        FROM threads
        WHERE cwd IS NOT NULL
        ORDER BY updated_ms DESC, id DESC
    """
    target = cwd.resolve()
    for row in connection.execute(query):
        row_dict = dict(row)
        value = row_dict.get("cwd")
        if not value:
            continue
        candidate = Path(value).resolve()
        if candidate == target or str(candidate).startswith(str(target) + os.sep):
            return row_dict
    raise LookupError(f"no Codex thread found for cwd: {target}")


def resolve_rollout_path(row: dict[str, Any], codex_home: Path) -> Path | None:
    rollout_path = Path(row["rollout_path"]) if row.get("rollout_path") else None
    if rollout_path and rollout_path.exists():
        return rollout_path

    thread_id = row.get("id")
    if not thread_id:
        return rollout_path

    for root_name in ("sessions", "archived_sessions"):
        root = codex_home / root_name
        if not root.exists():
            continue
        matches = sorted(root.rglob(f"*{thread_id}.jsonl"))
        if matches:
            return matches[0]

    return rollout_path


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


def summarize_arguments(arguments: Any, limit: int) -> str:
    if isinstance(arguments, (dict, list)):
        return truncate(json.dumps(arguments, ensure_ascii=False, sort_keys=True), limit)
    return truncate(arguments, limit)


def parse_rollout(
    path: Path,
    *,
    max_message_chars: int,
    max_output_chars: int,
    max_events: int,
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
            if summary and len(summaries) < max_events:
                summaries.append(truncate(summary, max_message_chars))
            continue

        if entry_type == "event_msg":
            event_type = payload.get("type")
            if event_type == "user_message":
                text = payload.get("message") or flatten_content(payload.get("text_elements"))
                append_message(
                    messages,
                    seen_messages,
                    role="user",
                    timestamp=timestamp,
                    source="event_msg",
                    text=text,
                    max_message_chars=max_message_chars,
                    max_events=max_events,
                )
            elif event_type == "agent_message":
                text = payload.get("message")
                if text and len(agent_updates) < max_events:
                    agent_updates.append(
                        {
                            "timestamp": timestamp,
                            "phase": payload.get("phase"),
                            "text": truncate(text, max_message_chars),
                        }
                    )
            elif event_type == "task_complete":
                final_outcome = truncate(
                    payload.get("message") or payload.get("info") or "task_complete",
                    max_message_chars,
                )
            continue

        if entry_type != "response_item":
            continue

        item_type = payload.get("type")
        if item_type == "message":
            role = payload.get("role")
            text = flatten_content(payload.get("content"))
            if role in {"user", "assistant"}:
                append_message(
                    messages,
                    seen_messages,
                    role=role,
                    timestamp=timestamp,
                    source="response_item",
                    text=text,
                    max_message_chars=max_message_chars,
                    max_events=max_events,
                )
                if role == "assistant" and text:
                    final_outcome = truncate(text, max_message_chars)
        elif item_type == "reasoning":
            summary = flatten_content(payload.get("summary") or payload.get("content"))
            if summary and len(summaries) < max_events:
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
            if isinstance(arguments, dict) and arguments.get("sandbox_permissions") == "require_escalated":
                call["requires_approval"] = True
                approval_requests.append(
                    {
                        "timestamp": timestamp,
                        "tool": payload.get("name"),
                        "justification": truncate(arguments.get("justification", ""), max_message_chars),
                        "commands": call["commands"],
                    }
                )
            if len(tool_calls) < max_events:
                tool_calls.append(call)
            if payload.get("call_id"):
                calls_by_id[payload["call_id"]] = call
        elif item_type == "function_call_output":
            output = str(payload.get("output", ""))
            call = calls_by_id.get(payload.get("call_id"), {})
            commands = call.get("commands", [])
            if looks_like_failure(output, commands):
                command_failures.append(
                    {
                        "timestamp": timestamp,
                        "tool": call.get("name"),
                        "commands": commands,
                        "exit_code": output_exit_code(output),
                        "output": truncate(output, max_output_chars),
                    }
                )

    return {
        "messages": messages,
        "agent_updates": agent_updates,
        "tool_calls": tool_calls,
        "command_failures": command_failures,
        "approval_requests": approval_requests,
        "summaries": summaries,
        "final_outcome": final_outcome,
    }


def build_output(
    *,
    row: dict[str, Any],
    codex_home: Path,
    rollout_path: Path | None,
    source: str,
    parsed: dict[str, Any],
    args: argparse.Namespace,
) -> dict[str, Any]:
    return {
        "read_only": True,
        "generated_at": dt.datetime.now(tz=dt.timezone.utc).isoformat(),
        "codex_home": str(codex_home),
        "source": source,
        "limits": {
            "max_message_chars": args.max_message_chars,
            "max_output_chars": args.max_output_chars,
            "max_events": args.max_events,
        },
        "thread": {
            "id": row.get("id"),
            "title": truncate(row.get("title"), args.max_message_chars),
            "cwd": row.get("cwd"),
            "created_at": iso_from_ms(row.get("created_ms")),
            "updated_at": iso_from_ms(row.get("updated_ms")),
            "archived": bool(row.get("archived")),
            "git_branch": row.get("git_branch"),
            "git_sha": row.get("git_sha"),
            "model": row.get("model"),
            "reasoning_effort": row.get("reasoning_effort"),
            "tokens_used": row.get("tokens_used"),
            "approval_mode": row.get("approval_mode"),
            "sandbox_policy": truncate(row.get("sandbox_policy"), args.max_message_chars),
            "first_user_message": truncate(row.get("first_user_message", ""), args.max_message_chars),
            "rollout_path": str(rollout_path) if rollout_path else None,
            "missing_rollout": not bool(rollout_path and rollout_path.exists()),
        },
        "session": parsed,
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--thread-id", default=os.environ.get("CODEX_THREAD_ID"))
    parser.add_argument(
        "--latest-for-cwd",
        help="Fallback: inspect the latest thread whose cwd is this path or a descendant.",
    )
    parser.add_argument(
        "--codex-home",
        default=os.environ.get("CODEX_HOME", "~/.codex"),
        help="Codex home directory.",
    )
    parser.add_argument("--max-message-chars", type=int, default=1200)
    parser.add_argument("--max-output-chars", type=int, default=1200)
    parser.add_argument("--max-events", type=int, default=120)
    parser.add_argument("--pretty", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    codex_home = Path(os.path.expanduser(args.codex_home)).resolve()

    try:
        with connect_state(codex_home) as connection:
            if args.thread_id:
                row = load_thread_by_id(connection, args.thread_id)
                source = "thread-id"
            elif args.latest_for_cwd:
                row = load_latest_for_cwd(connection, Path(args.latest_for_cwd))
                source = "latest-for-cwd"
            else:
                raise ValueError("no thread id available; pass --thread-id or --latest-for-cwd")

        rollout_path = resolve_rollout_path(row, codex_home)
        parsed: dict[str, Any]
        if rollout_path and rollout_path.exists():
            parsed = parse_rollout(
                rollout_path,
                max_message_chars=args.max_message_chars,
                max_output_chars=args.max_output_chars,
                max_events=args.max_events,
            )
        else:
            parsed = {"rollout_read_error": "rollout file not found"}

        output = build_output(
            row=row,
            codex_home=codex_home,
            rollout_path=rollout_path,
            source=source,
            parsed=parsed,
            args=args,
        )
        json.dump(output, sys.stdout, ensure_ascii=False, indent=2 if args.pretty else None)
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

#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path


TUI_SETTINGS = (
    ("notifications", '["agent-turn-complete", "approval-requested"]'),
    ("notification_method", '"bel"'),
    ("notification_condition", '"always"'),
)

TUI_HEADER_RE = re.compile(r"^\s*\[tui\]\s*(?:#.*)?$")
TABLE_HEADER_RE = re.compile(r"^\s*\[.+\]\s*(?:#.*)?$")
KEY_RE = re.compile(r"^\s*([A-Za-z0-9_-]+)\s*=")


def configure_text(text: str) -> str:
    lines = text.splitlines()
    tui_start = next(
        (index for index, line in enumerate(lines) if TUI_HEADER_RE.match(line)),
        None,
    )

    if tui_start is None:
        return append_tui_section(lines)

    tui_end = find_table_end(lines, tui_start)
    section = update_tui_section(lines[tui_start + 1 : tui_end])
    updated_lines = lines[: tui_start + 1] + section + lines[tui_end:]
    return "\n".join(updated_lines) + "\n"


def append_tui_section(lines: list[str]) -> str:
    updated_lines = list(lines)
    if updated_lines and updated_lines[-1] != "":
        updated_lines.append("")

    updated_lines.append("[tui]")
    updated_lines.extend(format_tui_settings())
    return "\n".join(updated_lines) + "\n"


def find_table_end(lines: list[str], start: int) -> int:
    for index in range(start + 1, len(lines)):
        if TABLE_HEADER_RE.match(lines[index]):
            return index

    return len(lines)


def update_tui_section(lines: list[str]) -> list[str]:
    values = dict(TUI_SETTINGS)
    seen = set()
    updated = []
    index = 0

    while index < len(lines):
        line = lines[index]
        match = KEY_RE.match(line)
        key = match.group(1) if match else None

        if key in values:
            if key not in seen:
                updated.append(f"{key} = {values[key]}")
                seen.add(key)
            index = find_value_end(lines, index)
            continue

        updated.append(line)
        index += 1

    missing_lines = [
        f"{key} = {value}" for key, value in TUI_SETTINGS if key not in seen
    ]

    if missing_lines and updated and updated[-1] != "":
        updated.append("")

    updated.extend(missing_lines)
    return updated


def find_value_end(lines: list[str], start: int) -> int:
    stack = []
    string_delimiter = ""
    multiline_string = False
    escaped = False
    saw_value = False

    for index in range(start, len(lines)):
        line = lines[index]
        offset = line.find("=") + 1 if index == start else 0

        while offset < len(line):
            char = line[offset]

            if string_delimiter:
                saw_value = True
                if multiline_string:
                    delimiter = string_delimiter * 3
                    if line.startswith(delimiter, offset):
                        string_delimiter = ""
                        multiline_string = False
                        offset += 3
                    else:
                        offset += 1
                    continue

                if string_delimiter == '"':
                    if escaped:
                        escaped = False
                    elif char == "\\":
                        escaped = True
                    elif char == '"':
                        string_delimiter = ""
                elif char == "'":
                    string_delimiter = ""

                offset += 1
                continue

            if char == "#":
                break

            if char.isspace():
                offset += 1
                continue

            if line.startswith('"""', offset) or line.startswith("'''", offset):
                string_delimiter = char
                multiline_string = True
                saw_value = True
                offset += 3
                continue

            if char in ("'", '"'):
                string_delimiter = char
                saw_value = True
                offset += 1
                continue

            if char == "[":
                stack.append("]")
            elif char == "{":
                stack.append("}")
            elif stack and char == stack[-1]:
                stack.pop()

            saw_value = True
            offset += 1

        if saw_value and not string_delimiter and not stack:
            return index + 1

    return start + 1


def format_tui_settings() -> list[str]:
    return [f"{key} = {value}" for key, value in TUI_SETTINGS]


def configure_file(path: Path) -> bool:
    text = path.read_text() if path.exists() else ""
    updated = configure_text(text)

    if updated == text:
        return False

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(updated)
    return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Configure Codex CLI terminal notifications for tmux."
    )
    parser.add_argument(
        "config",
        nargs="?",
        type=Path,
        default=Path.home() / ".codex" / "config.toml",
        help="Path to Codex config.toml.",
    )
    args = parser.parse_args()

    changed = configure_file(args.config)
    action = "Updated" if changed else "Already configured"
    print(f"{action} Codex notifications in {args.config}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

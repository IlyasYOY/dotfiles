#!/usr/bin/env python3
"""Summarize staged changes and recent commit style for commit drafting."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any


COMMIT_RE = re.compile(
    r"^(?P<type>[a-z]+)(?:\((?P<scope>[^)]+)\))?(?P<breaking>!)?: (?P<summary>.+)$"
)


def run_git(repo: Path, args: list[str]) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "git command failed")
    return result.stdout.rstrip("\n")


def resolve_repo(repo: str) -> Path:
    path = Path(repo).expanduser().resolve()
    try:
        root = run_git(path, ["rev-parse", "--show-toplevel"])
    except RuntimeError as exc:
        raise SystemExit(f"error: {path} is not a Git repository: {exc}") from exc
    return Path(root)


def split_records(raw: str) -> list[tuple[str, str, str]]:
    records: list[tuple[str, str, str]] = []
    for record in raw.split("\x1e"):
        record = record.strip("\n")
        if not record:
            continue
        parts = record.split("\x00", 2)
        if len(parts) != 3:
            continue
        records.append((parts[0], parts[1], parts[2].strip()))
    return records


def recent_commits(repo: Path, limit: int) -> list[dict[str, Any]]:
    raw = run_git(repo, [f"--no-pager", "log", f"-n{limit}", "--format=%H%x00%s%x00%b%x1e"])
    commits: list[dict[str, Any]] = []
    for commit_hash, subject, body in split_records(raw):
        match = COMMIT_RE.match(subject)
        commits.append(
            {
                "hash": commit_hash,
                "subject": subject,
                "body": body,
                "has_body": bool(body.strip()),
                "conventional": bool(match),
                "type": match.group("type") if match else None,
                "scope": match.group("scope") if match else None,
                "breaking": bool(match and match.group("breaking")),
                "summary": match.group("summary") if match else subject,
            }
        )
    return commits


def parse_name_status(raw: str) -> list[dict[str, str]]:
    changes: list[dict[str, str]] = []
    for line in raw.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        status = parts[0]
        if status.startswith(("R", "C")) and len(parts) >= 3:
            changes.append({"status": status, "path": parts[2], "old_path": parts[1]})
        elif len(parts) >= 2:
            changes.append({"status": status, "path": parts[1]})
    return changes


def diff_args(diff_source: str) -> list[str]:
    if diff_source == "staged":
        return ["diff", "--cached"]
    return ["diff", "HEAD"]


def diff_context(repo: Path, diff_source: str) -> dict[str, Any]:
    base = diff_args(diff_source)
    name_status = run_git(repo, [*base, "--name-status"])
    stat = run_git(repo, [*base, "--stat"])
    shortstat = run_git(repo, [*base, "--shortstat"])
    changes = parse_name_status(name_status)
    return {
        "source": diff_source,
        "has_changes": bool(changes),
        "file_count": len(changes),
        "changes": changes,
        "stat": stat,
        "shortstat": shortstat,
    }


def top_items(counter: Counter[str], limit: int = 5) -> list[dict[str, Any]]:
    return [{"value": value, "count": count} for value, count in counter.most_common(limit)]


def style_summary(commits: list[dict[str, Any]]) -> dict[str, Any]:
    type_counts: Counter[str] = Counter(
        commit["type"] for commit in commits if commit["type"]
    )
    scope_counts: Counter[str] = Counter(
        commit["scope"] for commit in commits if commit["scope"]
    )
    conventional_count = sum(1 for commit in commits if commit["conventional"])
    body_count = sum(1 for commit in commits if commit["has_body"])
    subjects = [commit["subject"] for commit in commits]
    notes: list[str] = []

    if commits and conventional_count >= max(1, round(len(commits) * 0.7)):
        notes.append("Recent history mostly uses Conventional Commit titles.")
    elif commits:
        notes.append("Recent history mixes Conventional Commit and plain titles.")
    else:
        notes.append("No recent commits were found.")

    if body_count:
        notes.append("Some recent commits include bodies; include one when it adds why.")
    else:
        notes.append("Recent commits omit bodies, but this task requires a why body.")

    if type_counts:
        common_types = ", ".join(item["value"] for item in top_items(type_counts, 3))
        notes.append(f"Common types: {common_types}.")
    if scope_counts:
        common_scopes = ", ".join(item["value"] for item in top_items(scope_counts, 3))
        notes.append(f"Common scopes: {common_scopes}.")

    return {
        "commit_count": len(commits),
        "conventional_count": conventional_count,
        "body_count": body_count,
        "top_types": top_items(type_counts),
        "top_scopes": top_items(scope_counts),
        "recent_subjects": subjects[: min(6, len(subjects))],
        "notes": notes,
    }


def build_context(args: argparse.Namespace) -> dict[str, Any]:
    repo = resolve_repo(args.repo)
    commits = recent_commits(repo, args.limit)
    diff = diff_context(repo, args.diff_source)
    reason = args.reason.strip() if args.reason else ""
    return {
        "repo": str(repo),
        "diff": diff,
        "style": style_summary(commits),
        "reason": {
            "provided": bool(reason),
            "text": reason,
            "needs_clarification": not bool(reason),
            "guidance": (
                "Use the provided reason in the commit body."
                if reason
                else "If the user request or conversation does not explain why, ask for clarification."
            ),
        },
    }


def markdown_list(items: list[dict[str, Any]]) -> str:
    if not items:
        return "- None"
    return "\n".join(f"- {item['value']}: {item['count']}" for item in items)


def render_markdown(context: dict[str, Any]) -> str:
    diff = context["diff"]
    style = context["style"]
    reason = context["reason"]
    paths = "\n".join(
        f"- {change['status']} {change['path']}" for change in diff["changes"]
    )
    if not paths:
        paths = "- No changed files found"
    stat = diff["stat"] or "No diff stat available"

    return f"""# Commit Context

## Diff

- Repository: `{context["repo"]}`
- Source: `{diff["source"]}`
- Files changed: {diff["file_count"]}
- Short stat: {diff["shortstat"] or "none"}

## Changed Files

{paths}

## Diff Stat

```text
{stat}
```

## Recent Commit Style

- Commits analyzed: {style["commit_count"]}
- Conventional titles: {style["conventional_count"]}/{style["commit_count"]}
- Commits with bodies: {style["body_count"]}/{style["commit_count"]}

Top types:

{markdown_list(style["top_types"])}

Top scopes:

{markdown_list(style["top_scopes"])}

Style notes:

{chr(10).join(f"- {note}" for note in style["notes"])}

Recent subjects:

{chr(10).join(f"- {subject}" for subject in style["recent_subjects"]) or "- None"}

## Reason

- Explicit reason supplied: {"yes" if reason["provided"] else "no"}
- Needs clarification: {"yes" if reason["needs_clarification"] else "no"}
- Guidance: {reason["guidance"]}
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Summarize staged changes and recent commit style for commit drafting."
    )
    parser.add_argument(
        "--repo",
        default=".",
        help="Git repository to inspect. Defaults to the current directory.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=12,
        help="Number of recent commits to analyze. Defaults to 12.",
    )
    parser.add_argument(
        "--diff-source",
        choices=("staged", "all"),
        default="staged",
        help="Changes to inspect. Defaults to staged changes only.",
    )
    parser.add_argument(
        "--reason",
        default="",
        help="Explicit reason for the change, if already known from context.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit structured JSON instead of Markdown.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.limit < 1:
        print("error: --limit must be at least 1", file=sys.stderr)
        return 2

    try:
        context = build_context(args)
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(context, indent=2, sort_keys=True))
    else:
        print(render_markdown(context))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

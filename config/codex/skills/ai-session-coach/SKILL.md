---
name: ai-session-coach
description: Analyze all unarchived local Codex sessions by project using sub-agents, then recommend exactly 5 ways to make AI-assisted work more effective. Use when the user asks to inspect recent Codex/AI sessions, improve their AI workflow, identify recurring friction, propose AGENTS.md improvements, create prompt checklists, or derive working habits from session history.
---

# AI Session Coach

Use this skill to turn local Codex session history into practical workflow improvements.
The analysis step is read-only. The optional archive step must only archive session IDs from the current snapshot manifest, and only after explicit user confirmation.

## Workflow

1. Treat the user's request as `analysis_focus`.
    - Do not ask for a project or time window by default.
    - Default scope is every unarchived session in `~/.codex/state_5.sqlite`.
    - Exclude the current live thread with `--exclude-current-thread`.
2. Run `scripts/collect_sessions.py` from this skill directory in snapshot mode.
    - Use `--unarchived --exclude-current-thread`.
    - Use `--out-dir` under `/tmp` so generated packs do not touch the repo.
    - Pass the user's request through `--analysis-focus`.
    - Only add `--project`, `--since`, or `--until` if the user explicitly narrows scope.
3. Read `manifest.json` to identify project packs.
    - Projects are grouped by exact `cwd` from Codex threads.
    - If there are no project packs, say that there are no unarchived sessions to analyze.
4. Delegate each project pack to a separate sub-agent when sub-agent tools are available.
    - Give each sub-agent only its project JSON path and the `analysis_focus`.
    - Ask for a compact project summary: repeated friction, strong evidence snippets, suggested durable fixes, and confidence.
    - The main agent should not load raw sessions for every project unless a sub-agent result is missing or ambiguous.
5. Synthesize the sub-agent summaries into exactly 5 recommendations, prioritized by expected leverage.
6. After returning the 5 recommendations, ask whether to archive the exact snapshot.
    - If the user does not explicitly confirm archiving, stop.
    - If the manifest path is not available in the current conversation, ask for it instead of guessing.
    - Never archive all unarchived sessions; archive only `session_ids` listed in that manifest.
    - Never archive the current live thread; `archive_sessions.py` also skips `CODEX_THREAD_ID`.
7. If the user confirms archive intent, run `scripts/archive_sessions.py --manifest <manifest> --pretty` first and show the dry-run summary.
8. Run `scripts/archive_sessions.py --manifest <manifest> --apply --pretty` only after the user explicitly confirms the dry-run summary.

Example command:

```bash
python3 config/codex/skills/ai-session-coach/scripts/collect_sessions.py \
    --unarchived \
    --exclude-current-thread \
    --out-dir /tmp/ai-session-coach \
    --analysis-focus "find recurring AI workflow friction" \
    --pretty
```

Example sub-agent prompt:

```text
Analyze this ai-session-coach project pack only: /tmp/ai-session-coach/project-001-example.json.
Use analysis_focus from the pack. Return a compact summary with:
- project cwd and session count
- 3-5 recurring patterns, each with short evidence
- recommended durable fixes
- confidence and any thin-data caveats
Do not modify files or archive sessions.
```

Example archive dry-run:

```bash
python3 config/codex/skills/ai-session-coach/scripts/archive_sessions.py \
    --manifest /tmp/ai-session-coach/manifest.json \
    --pretty
```

Example archive apply after explicit confirmation:

```bash
python3 config/codex/skills/ai-session-coach/scripts/archive_sessions.py \
    --manifest /tmp/ai-session-coach/manifest.json \
    --apply \
    --pretty
```

## Recommendation Priorities

Prefer durable fixes in this order:

1. Project AGENTS.md additions or corrections.
2. A reusable user prompt checklist or task template.
3. Repo-specific commands, tests, or verification steps to mention up front.
4. New reusable skills or scripts only when the same work repeats across sessions.
5. Conversation habits such as giving acceptance criteria, constraints, examples, or stop conditions earlier.

Use short evidence snippets only. Do not dump raw transcripts or long tool outputs.
Redact secrets or tokens if any appear in evidence.

## Response Contract

Return exactly 5 numbered recommendations. Each recommendation must include:

- **Recommendation**: one direct action.
- **Evidence**: session title/date plus a short observed pattern or snippet.
- **Action**: concrete next step; include a ready-to-paste AGENTS.md snippet when relevant.
- **Expected impact**: why this improves future AI work.

If the available session data is thin, still return 5 recommendations, but label weaker items as lower confidence.

## Script Notes

`scripts/collect_sessions.py` uses only the Python standard library. It reads:

- `~/.codex/state_5.sqlite` for session metadata such as `cwd`, title, rollout path, timestamps, branch, archive state, model, and token usage.
- JSONL rollout files referenced by the database for user/assistant messages, tool calls, command failures, approval requests, summaries, and final outcomes.
- Nearby `AGENTS.md` files for matched project directories, with bounded excerpts.

Use script options to keep output compact:

- `--unarchived` limits the snapshot to unarchived sessions.
- `--exclude-current-thread` skips `CODEX_THREAD_ID` if it is set.
- `--exclude-thread` skips an explicit thread ID; repeat it for multiple threads.
- `--out-dir` writes `manifest.json` plus one bounded JSON pack per exact `cwd`.
- `--analysis-focus` copies the user request into the manifest and project packs.
- `--max-sessions` limits session count; in `--unarchived` mode the default is unlimited.
- `--max-message-chars` limits each message or snippet.
- `--max-output-chars` limits tool output evidence.
- `--max-events-per-session` limits messages and tool calls per session.

`scripts/collect_sessions.py` must remain read-only with respect to Codex state and session storage. It must not update `state_5.sqlite`, move files from `sessions/`, or write to `archived_sessions/`.

`scripts/archive_sessions.py` is the only archival tool for this skill:

- `--manifest` is required.
- Dry-run is the default.
- `--apply` is required for real archiving.
- `--codex-home` may override `manifest.codex_home` for testing against a temporary Codex copy.
- It reads target sessions only from `manifest.projects[].session_ids`.
- It creates `state_5.sqlite.bak-ai-session-coach-<timestamp>` before applying DB changes.
- It reports `archived`, `skipped_current_thread`, `already_archived`, `missing_rollout`, and `errors`.

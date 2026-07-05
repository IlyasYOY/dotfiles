---
name: ai-session-coach
description: Explicit workflow coach for analyzing unarchived OpenCode sessions.
disable-model-invocation: true
---

# AI Session Coach (OpenCode)

Turn local OpenCode session history into exactly 5 practical workflow
recommendations. Analysis is read-only. Archiving is optional and requires two
explicit confirmations: one for intent, one after dry-run review. Dry-run is the
default; never pass `--apply` unless the user explicitly confirms it after
reviewing the dry-run output.

## Workflow

1. Treat the user's request as `analysis_focus`.
   - Default scope: every unarchived session in
     `~/.local/share/opencode/opencode.db`.
   - Do not ask for a project or time window by default.
   - Add `--project`, `--since`, or `--until` only when the user narrows scope.

2. Collect a snapshot:
   - Run this skill's `scripts/collect_sessions.py`.
   - Use `--unarchived --exclude-current-session`.
   - Write packs under `/tmp`, not the repository.
   - Pass `--analysis-focus` with the user's request.
   - If the current OpenCode session ID is known, pass it as
     `--current-session-id <id>` so the live thread is excluded.

   Completion criterion: `manifest.json` exists, names the generated project
   packs, and excludes the current live session when its ID is available.

3. Read `manifest.json`.
   - If there are no project packs, say there are no unarchived OpenCode
     sessions to analyze and stop.
   - Projects are grouped by exact `session.directory`.

4. Analyze each project pack.
   - Prefer one sub-agent per project when sub-agent tools are available.
   - Give each sub-agent only its project JSON path and `analysis_focus`.
   - Ask for recurring friction, evidence snippets, durable fixes, confidence,
     and thin-data caveats.
   - If sub-agents are unavailable or a result is ambiguous, inspect the pack
     directly.

   Completion criterion: every project pack in the manifest is represented in
   the synthesis or explicitly excluded with a reason.

5. Synthesize exactly 5 recommendations, prioritized by leverage.
   - Prefer durable fixes over vague process advice.
   - Use short evidence snippets only; redact secrets or tokens.

6. Ask whether to archive the exact snapshot.
   - If the user does not explicitly confirm, stop.
   - If the manifest path is missing from conversation context, ask for it.
   - Never archive all unarchived sessions; archive only IDs from this manifest.

7. If archiving is confirmed, run dry-run first:
   - `scripts/archive_sessions.py --manifest <manifest> --pretty`
   - Show the dry-run summary.

8. Apply archiving only after explicit dry-run confirmation:
   - `scripts/archive_sessions.py --manifest <manifest> --apply --pretty`
   - If the current OpenCode session ID is known, also pass
     `--current-session-id <id>`.

## Recommendation Priorities

1. Project `AGENTS.md` additions or corrections.
2. Reusable user prompt checklist or task template.
3. Repo-specific commands, tests, or verification steps to mention up front.
4. New reusable skills, commands, or scripts only when work repeats across
   sessions.
5. Conversation habits: acceptance criteria, constraints, examples, or stop
   conditions earlier.

## Response Contract

Return exactly 5 numbered recommendations. Each includes:

- **Recommendation**: one direct action.
- **Evidence**: session title/date plus a short observed pattern or snippet.
- **Action**: concrete next step; include a ready-to-paste `AGENTS.md` snippet
  when relevant.
- **Expected impact**: why this improves future AI work.

If data is thin, still return 5 recommendations and label weaker items lower
confidence.

## Script Reference

Example collection:

```bash
python3 config/opencode/skills/ai-session-coach/scripts/collect_sessions.py \
    --unarchived \
    --exclude-current-session \
    --out-dir /tmp/ai-session-coach-opencode \
    --analysis-focus "find recurring AI workflow friction" \
    --pretty
```

`collect_sessions.py` is read-only with respect to OpenCode state. It reads
session metadata and message parts from `~/.local/share/opencode/opencode.db`,
bounded log excerpts, session-diff excerpts, todos, and nearby `AGENTS.md`
files.

Useful collection options: `--exclude-session`, `--current-session-id`,
`--project`, `--since`, `--until`, `--max-sessions`, `--max-message-chars`,
`--max-output-chars`, and `--max-events-per-session`.

`archive_sessions.py` is the only archival tool for this skill. Dry-run is the
default; `--apply` is required for real archiving. It reads target sessions from
`manifest.projects[].session_ids`, creates a timestamped DB backup before any
apply, sets `session.time_archived`, and reports archived/skipped/error counts.

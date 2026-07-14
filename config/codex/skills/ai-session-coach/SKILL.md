---
name: ai-session-coach
description: Analyze Codex session history since the last successful coaching run and return exactly five practical workflow improvements. Use when the user explicitly invokes the AI session coach or asks to review recent Codex sessions for recurring friction, instruction gaps, or reusable workflow improvements.
---

# AI Session Coach

Turn local Codex session history into exactly 5 practical workflow
recommendations. Preserve every session. After a successful complete run, store
a checkpoint so the next run skips sessions that have not changed.

## Workflow

1. Treat the user's request as `analysis_focus`.
   - Default to every session updated since the last successful full run.
   - Add `--project`, `--since`, or `--until` only when the user narrows scope.
   - Treat narrowed runs as ad hoc; never advance the global checkpoint for
     them.

2. Collect a snapshot:
   - Run this skill's `scripts/collect_sessions.py`.
   - Use `--incremental --exclude-current-thread`.
   - Write packs under `/tmp`, not the repository.
   - Pass `--analysis-focus` with the user's request.
   - Keep the default internal-session filter enabled. It excludes Codex
     subagents, approval-review fallbacks, earlier session-coach runs, and
     model-switch-only sessions while recording them in
     `manifest.internal_sessions`.
   - On the first checkpointed run, let incremental mode use unarchived
     sessions as the migration baseline. Do not add `--unarchived` manually.
   - Use `--ignore-checkpoint` only for an intentional historical rerun; such a
     run must not advance the checkpoint.

   Completion criterion: `manifest.json` exists, names the generated project
   packs, reports checkpoint and internal-exclusion details, and excludes the
   current live thread from analyzed and internal IDs.

3. Read `manifest.json`.
   - If there are no project packs, say there are no new user sessions to
     analyze, then record the checkpoint for a complete default run.
   - Projects are grouped by exact `cwd`.

4. Analyze each project pack.
   - Prefer one sub-agent per project when sub-agent tools and repository rules
     allow delegation.
   - Give each sub-agent only its project JSON path and `analysis_focus`.
   - Ask for recurring friction, evidence snippets, durable fixes, confidence,
     and thin-data caveats.
   - If sub-agents are unavailable or a result is ambiguous, inspect the pack
     directly.

   Completion criterion: represent every project pack in the synthesis or
   explicitly exclude it with a reason.

5. Synthesize exactly 5 recommendations, prioritized by leverage.
   - Prefer durable fixes over vague process advice.
   - Use short evidence snippets only; redact secrets or tokens.

6. Record a checkpoint only for a successful complete default run:
   - Request approval before writing under `~/.codex` when required by the
     active environment instructions.
   - Run `scripts/record_checkpoint.py --manifest <manifest> --pretty` after
     synthesis and before returning the response.
   - If checkpoint recording fails, return the recommendations with a concise
     warning. Do not claim the run was checkpointed; the next run may repeat
     the same window.

## Recommendation Priorities

1. Project `AGENTS.md` additions or corrections.
2. Reusable user prompt checklist or task template.
3. Repo-specific commands, tests, or verification steps to mention up front.
4. New reusable skills or scripts only when work repeats across sessions.
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
confidence. If there are no new user sessions, return the no-new-sessions
message instead of inventing recommendations.

## Script Reference

```bash
python3 config/codex/skills/ai-session-coach/scripts/collect_sessions.py \
    --incremental \
    --exclude-current-thread \
    --out-dir /tmp/ai-session-coach \
    --analysis-focus "find recurring AI workflow friction" \
    --pretty
```

`collect_sessions.py` reads `~/.codex/state_5.sqlite`, bounded rollout
excerpts, nearby `AGENTS.md` files, and the machine-local checkpoint. It never
changes Codex sessions. Incremental filtering uses session `updated_at`, so a
session that continues after a prior snapshot is eligible again.

Useful options: `--exclude-thread`, `--max-sessions`, `--max-message-chars`,
`--max-output-chars`, and `--max-events-per-session`. Use
`--include-internal` only when internal orchestration sessions belong in the
analysis packs.

`record_checkpoint.py` writes `~/.codex/ai-session-coach-state.json`
atomically. It rejects project/date-scoped, limited, checkpoint-ignored, or
custom-exclusion manifests so a partial run cannot hide unchecked sessions.

---
name: taskwarrior
description: Use Taskwarrior (`task`) from Codex for reading, creating, updating, organizing, configuring, syncing, importing/exporting, and integrating command-line tasks. Use when the user asks to inspect or modify Taskwarrior tasks, compose safe `task` commands, work with `.taskrc`, custom reports, contexts, UDAs, hooks, JSON export/import, sync, or TaskChampion/Taskwarrior integration workflows.
---

# Taskwarrior

## Overview

Use the `task` CLI as the source of truth. Taskwarrior data is live user data:
start read-only, prefer structured output, and only mutate tasks when the user
clearly requested that exact kind of change.

Do not read or write Taskwarrior database files directly. Use `task export`,
`task import`, `_get`, reports, and documented CLI/config commands.

## Reference Selection

Load only the references needed for the request:

- `references/daily-cli.md` - add/list/modify/done/start/stop/delete/export,
  live-data safety, IDs vs UUIDs, and common task operations.
- `references/filters-reports-dates.md` - filters, shell quoting, reports,
  tags, priority, dates, durations, and recurrence.
- `references/configuration.md` - `.taskrc`, temporary overrides, environment
  isolation, contexts, UDAs, diagnostics, and permanent config changes.
- `references/integration.md` - JSON import/export, `_get`/DOM, hooks, sync,
  TaskChampion, and third-party application rules.

## Workflow

1. Check local availability when command execution is needed:
   `command -v task` and `task --version`.
2. For read-only inspection, prefer:
   - `task rc.color=off <filter> count`
   - `task rc.color=off <filter> list`
   - `task rc.color=off rc.json.array=on <filter> export`
3. Before live bulk changes, identify the affected tasks with `count` and
   `ids` or `export`. Use UUIDs for multi-step operations when IDs could change.
4. Before `delete`, `purge`, `import`, `sync`, permanent `config` changes, or
   hook installation, state the exact impact and require explicit user intent.
5. Prefer temporary `rc.*` overrides over permanent configuration changes unless
   the user asked to change `.taskrc`.
6. Report what changed and how it was verified.

## Safety Rules

- Never run `purge`, broad `delete`, broad `modify`, `import`, or `sync`
  from an ambiguous natural-language request.
- Never disable confirmations globally as part of normal use.
- Never use external file-sync tools on Taskwarrior 3 task storage; use
  documented `task sync`/TaskChampion mechanisms.
- Never install or enable hooks without reviewing the hook content and testing
  in an isolated `TASKRC`/`TASKDATA` environment first.
- If a command may affect many tasks, show the filter and count before running
  the mutation.

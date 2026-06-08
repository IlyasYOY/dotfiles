# Integration

Read this when using Taskwarrior from scripts, importing/exporting JSON,
writing hooks, syncing tasks, or integrating Taskwarrior/TaskChampion with
other systems.

Source docs: https://taskwarrior.org/docs/commands/export/,
https://taskwarrior.org/docs/commands/_get/, https://taskwarrior.org/docs/dom/,
https://taskwarrior.org/docs/hooks/, https://taskwarrior.org/docs/hooks2/,
https://taskwarrior.org/docs/hooks_guide/,
https://taskwarrior.org/docs/3rd-party/,
https://taskwarrior.org/docs/sync/,
https://taskwarrior.org/docs/upgrade-3/,
https://taskwarrior.org/docs/task/

## JSON Export and Import

Use `task export` for structured reads:

```bash
task rc.json.array=on project:Home export
task rc.json.array=off project:Home export
```

Export includes derived values such as `id` and `urgency`; they are useful for
clients but are not stored task fields. Taskwarrior JSON dates use UTC forms
such as `YYYYMMDDTHHMMSSZ`.

Use `task import` to write JSON back to Taskwarrior. Treat import as a live data
mutation and confirm first:

```bash
task import tasks.json
```

For add-ons and scripts:

- Produce and consume UTF-8.
- Use `export` and `import`; do not read or modify Taskwarrior database files.
- Preserve unknown fields unless there is a clear reason to remove them.
- Test imports against isolated `TASKRC`/`TASKDATA` first.

## DOM and Helper Commands

Use `_get` and helper commands for script-friendly reads:

```bash
task _get 12.description
task _get 12.entry 12.modified
task _get rc.report.next.columns
task _get 12.uuid
task _projects
task _tags
task _unique project
```

Helper commands are intended for add-ons and usually avoid extra human-facing
output.

## Hooks

Hooks run scripts during Taskwarrior events. Installing hook scripts is as
sensitive as installing any executable code.

Default hook location is the `hooks` directory under `data.location`, commonly
`~/.task/hooks`. Hook script names begin with the event:

```text
on-launch
on-exit
on-add
on-modify
on-add-require-project
```

Events:

- `on-launch` can prevent launch before normal processing.
- `on-exit` runs after processing, before output.
- `on-add` can approve, deny, or modify a new task.
- `on-modify` can approve, deny, or modify an existing task change.

Hooks exchange JSON on stdin/stdout according to the event. `on-add` receives
one task and must emit one task to change it. `on-modify` receives original and
modified tasks and can emit the final modified task. Non-zero exit status stops
processing and ignores emitted task JSON.

Hooks v2 keeps the v1 input/output model and adds command-line context such as
API version, original args, command, rc path, data path, and Taskwarrior
version.

Hook validation workflow:

1. Read the hook code.
2. Test the script directly with representative JSON.
3. Test with isolated `TASKRC` and `TASKDATA`.
4. Use `task diagnostics` and temporary `rc.debug.hooks=1` or
   `rc.debug.hooks=2` when debugging.
5. Only then install or enable the hook in live data.

## Sync

Taskwarrior sync shares changes between replicas with `task sync`. A change
usually needs one sync on the source replica and one sync on the destination
replica before both sides see it.

Taskwarrior 3 sync/storage is based on TaskChampion. Do not use file-sync tools
such as rsync, Syncthing, or Git against the Taskwarrior 3 task database. Use a
documented TaskChampion sync backend or server.

Taskwarrior 3 does not sync with the old `taskd` protocol. When upgrading from
Taskwarrior 2.x, follow the official Taskwarrior 3 upgrade flow and disable
hooks during import when instructed by the docs:

```bash
task import-v2 rc.hooks=0
```

Treat `task sync` as high impact. Once changes are synchronized, local undo
boundaries may no longer cover previous operations.

## TaskChampion Representation

TaskChampion exposes tasks as key/value maps. Taskwarrior manages higher-level
behaviors such as recurrence. Integration-specific data should use namespaced
UDA-style keys when possible, for example `devsync.github.issue-id`.

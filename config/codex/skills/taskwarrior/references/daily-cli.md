# Daily CLI

Read this when the user wants to inspect, add, update, complete, annotate,
start, stop, delete, or export tasks with the `task` command.

Source docs: https://taskwarrior.org/docs/syntax/,
https://taskwarrior.org/docs/commands/, https://taskwarrior.org/docs/examples/,
https://taskwarrior.org/docs/commands/export/,
https://taskwarrior.org/docs/ids/

## Command Shape

Taskwarrior command lines have this shape:

```bash
task <override> <filter> <command> <modifications>
```

Use full command names instead of abbreviations when composing commands for a
user. Put filters before commands and modifications after commands.

## Read-Only Commands

Common safe inspection commands:

```bash
task rc.color=off next
task rc.color=off list
task rc.color=off +work status:pending list
task rc.color=off 12 info
task rc.color=off project:Home count
task rc.color=off project:Home ids
task rc.color=off rc.json.array=on project:Home export
task _projects
task _tags
task _columns
```

For machine parsing, prefer `export` over parsing table output. `export`
accepts filters. With `rc.json.array=on`, output is a JSON array; with
`rc.json.array=off`, output is one JSON object per line.

## Creating Tasks

Use `task add` with attributes and tags inline:

```bash
task add "Pay rent" project:Home due:eom priority:H +finance
task add "Read Taskwarrior docs" +learning wait:tomorrow
```

For descriptions or project names with spaces, quote the value:

```bash
task add "Rake leaves" project:'Home & Garden'
```

## Updating Tasks

Use IDs for one immediate command, UUIDs for multi-step or scripted work.

```bash
task 12 modify due:eom priority:H +next
task 12 modify due:
task 12 annotate "Called landlord"
task 12 append "after lunch"
task 12 prepend "URGENT:"
```

Bulk modification must be preceded by a count or export:

```bash
task project:OldName status:pending count
task project:OldName status:pending modify project:NewName
```

## Completing, Starting, Stopping

```bash
task 12 done
task 12 start
task 12 stop
```

`start` and `stop` mark active work. They are not a full time-tracking system;
Taskwarrior can record start/stop annotations depending on configuration.

## Deleting and Purging

`delete` marks tasks deleted. `purge` permanently removes tasks and should be
treated as destructive.

```bash
task 12 delete
```

Before deleting more than one task, show the filter and count. Do not use
`purge` unless the user explicitly asked for permanent removal.

## IDs and UUIDs

Task IDs are convenient but can change when the working set is rebuilt.
Completed and deleted tasks leave the working set. UUIDs are permanent.

Useful mappings:

```bash
task _get 12.uuid
task _get <uuid>.id
```

Use UUIDs in automation, multi-step edits, import/export reconciliation, and
anything that crosses a report refresh.

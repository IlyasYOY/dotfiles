# Configuration

Read this when working with `.taskrc`, temporary overrides, contexts, UDAs,
diagnostics, alternate task data, or permanent config changes.

Source docs: https://taskwarrior.org/docs/configuration/,
https://taskwarrior.org/docs/context/, https://taskwarrior.org/docs/udas/,
https://taskwarrior.org/docs/help/, https://taskwarrior.org/docs/man/taskrc.5/

## Configuration Files and Overrides

Taskwarrior stores configuration in `.taskrc`; the minimal required setting is
the task data location:

```ini
data.location=~/.task
```

`task config` permanently changes `.taskrc`:

```bash
task config regex off
task config default.command long
task config default.command
```

Prefer one-command overrides when the user did not ask for a permanent config
change:

```bash
task rc.color=off list
task rc.regex=off /literal/ list
task rc.data.location=/alternate/path/.task list
```

Environment variables can isolate config and data:

```bash
TASKRC=/path/to/taskrc TASKDATA=/path/to/taskdata task list
```

Use isolated `TASKRC` and `TASKDATA` for testing hooks, imports, and examples
that should not affect live tasks.

## Inspection and Diagnostics

Useful config and troubleshooting commands:

```bash
task show
task show report.next
task show context
task diagnostics
task help
man task
man taskrc
man task-sync
```

`task show` also surfaces unrecognized settings, which can indicate typos or
obsolete options.

## Contexts

A context is a named filter that becomes an implicit filter for reports and
commands that accept filters.

```bash
task context define work +work or +freelance
task context define home -work -freelance
task context work
task context show
task context list
task context none
task context delete work
```

Contexts are stored as `rc.context` and `rc.context.<name>` settings. Context
filters are implicitly grouped so they can contain logic.

## User Defined Attributes

UDAs add metadata fields. Supported UDA types include `string`, `numeric`,
`date`, and `duration`.

```bash
task config uda.estimate.type numeric
task config uda.estimate.label Est
task add "Paint door" project:Home estimate:4
```

String UDAs may restrict values:

```bash
task config uda.size.type string
task config uda.size.label Size
task config uda.size.values large,medium,small
task config uda.size.default medium
```

UDAs can affect urgency:

```bash
task config urgency.uda.size.coefficient 2.8
```

Avoid orphaning UDA data. Removing a UDA definition can preserve stored data but
make it unavailable for normal filtering/reporting until the UDA is restored.

For integrations, prefer namespaced UDA names such as `devsync.github.issue-id`
when the target Taskwarrior version and config allow it.

## Config Safety

Permanent config changes affect future `task` commands. Before changing config:

1. Inspect the current value with `task show <setting>`.
2. Prefer a temporary `rc.*` override if the change is only needed once.
3. For report/context/UDA changes, state the exact setting names and values.
4. Verify with `task show <setting-prefix>` and one representative command.

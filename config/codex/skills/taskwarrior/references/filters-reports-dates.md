# Filters, Reports, Dates

Read this when composing filters, reports, date expressions, tag logic,
priority changes, or recurrence.

Source docs: https://taskwarrior.org/docs/filter/,
https://taskwarrior.org/docs/report/, https://taskwarrior.org/docs/dates/,
https://taskwarrior.org/docs/durations/, https://taskwarrior.org/docs/tags/,
https://taskwarrior.org/docs/priority/

## Filters

Basic filter forms:

```bash
task status:pending count
task project:Home list
task project: list
task +work list
task -work list
task /pattern/ list
```

Multiple filter terms imply `and`:

```bash
task project:Home -work list
task project:Home and -work list
```

Use explicit logic for alternatives:

```bash
task project:Home or project:Garden list
task +this xor +that list
```

Parentheses must be quoted or escaped for the shell:

```bash
task 'project:Home and (priority:H or priority:M)' list
task project:Home and \( priority:H or priority:M \) list
```

When searching for an empty value inside parentheses, keep the trailing space:
`'(project: )'`, not `'(project:)'`.

## Reports

Useful built-in reports include `next`, `ready`, `list`, `ls`, `long`,
`active`, `blocked`, `blocking`, `completed`, `overdue`, `waiting`, `all`,
`projects`, `tags`, `summary`, `reports`, and `diagnostics`.

Report filters combine with command-line filters. For example, `list` already
filters pending tasks, so `task project:Home list` means pending Home tasks.
To inspect beyond a report's default filter, use an appropriate report such as
`all` or temporarily clear a report filter:

```bash
task rc.report.list.filter: list
task all
```

Custom reports are configuration entries:

```bash
task config report.simple.description 'Simple list of open tasks by project'
task config report.simple.columns 'id,project,description.count'
task config report.simple.labels 'ID,Proj,Desc'
task config report.simple.sort 'project+/,entry+'
task config report.simple.filter 'status:pending'
task simple
```

Inspect supported columns/formats first:

```bash
task _columns
task columns description
task show report.next
```

## Dates and Durations

Common date attributes: `due`, `wait`, `scheduled`, `until`, `entry`, `end`,
`modified`, and `start`.

Taskwarrior accepts absolute dates plus named dates such as `today`,
`tomorrow`, `yesterday`, `eod`, `eom`, `eow`, `later`, and weekdays/months.
Use `task calc` to verify date expressions:

```bash
task calc eom
task add "Pay rent" due:eom wait:due-4days
task entry.after:today-4days list
task end.after:today-1wk completed
```

When reporting relative dates back to a user, include the resolved absolute
date if ambiguity matters.

Duration values include forms such as `4hours`, `3days`, `1wk`, `monthly`, and
`annual`. They are used in recurrence and duration UDAs.

## Tags, Virtual Tags, Priority

Tags are one-word labels:

```bash
task add "Paint walls" +home +weekend
task +home list
task 12 modify +renovate -weekend
```

Virtual tags are computed filters. Common examples:

```bash
task +DUETODAY list
task +DUE -DUETODAY list
task +WEEK list
task +OVERDUE list
task +TAGGED list
task +UNBLOCKED list
```

Priority is a built-in UDA in modern Taskwarrior:

```bash
task 12 modify priority:H
task 12 modify priority:
```

## Recurrence

Recurring tasks use `recur` with dates such as `due` and optional `until`:

```bash
task add "Pay rent" due:28th recur:monthly until:now+1yr
task add "Do weekly review" due:monday recur:weekly
```

Avoid inventing recurrence behavior. Inspect `task recurring`, `task <id> info`,
and current configuration when changing recurring tasks.

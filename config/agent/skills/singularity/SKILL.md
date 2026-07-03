---
name: singularity
description: >
  Capture a task into Singularity. Use when the user wants to create or add a
  task, todo, or reminder in Singularity.
---

Capture a task into Singularity: determine each property from real sources
before creating it.

## Workflow

1. **Title** — one sentence starting with a verb.
2. **Note** — a few sentences of context when needed. Ground every claim in
   user-provided data or a linked source (file, web, docs).
3. **Tags** — assign from existing Singularity tags; look them up rather than
   inventing names.
4. **Project** — assign to an existing Singularity project; look it up to get a
   valid id.
5. **Schedule** — if the task is time-bound, find a start date/time and
   duration, then check existing Singularity tasks and calendar events for
   overlaps before settling the slot. Skip if the task has no time component.

Completion criterion: every property above has a value, or an explicit reason
it is skipped.

## When the request is too vague

If a required property cannot be grounded and the request is too vague to
capture faithfully, do not guess — offer a `grilling` session to draw out the
missing detail.

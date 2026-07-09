---
name: singularity
description: >
  Capture, update, or organize a task in Singularity. Use when the user wants
  to add a task, todo, reminder, deadline, or scheduled work item.
---

Capture tasks as **reliable handoffs**: preserve the user's intent, fit the
existing system, and verify that Singularity saved what was requested.

## Workflow

1. **Ground the request** — use user-provided details and linked sources for
   every claim. Inspect existing tasks, projects, tags, and calendar data when
   they are relevant. Do not fabricate context.
2. **Shape the task** — write a short, action-led title. Add a concise note
   only when it makes the future task actionable; retain essential source links,
   constraints, and decisions rather than restating the whole conversation.
3. **Reuse the taxonomy** — look up existing tags and projects before assigning
   them. Prefer the user's established organization to a new project, tag, or
   naming convention.
4. **Schedule deliberately** — schedule only when the request supplies, or a
   source establishes, the necessary date, time, duration, and timezone. For a
   time-bound task, check relevant existing tasks and calendar events for
   conflicts before choosing a slot. Leave unscheduled work unscheduled.
5. **Write minimally** — create or update only the intended task and fields.
   When editing a task whose current note cannot be read, do not claim to append
   to it; ask before replacing it.
6. **Read back** — verify the saved task's title, note when applicable, project,
   tags, and scheduling fields. Correct any mismatch before reporting success.

Completion criterion: every requested property is grounded and persisted, or
has an explicit reason it was intentionally skipped.

## Ambiguity and communication

- Make reasonable, low-risk defaults without a long interrogation.
- Ask one focused question when an unanswered detail could materially change
  the task's meaning, placement, or schedule. Offer a `grilling` session when
  several design decisions remain.
- State material assumptions before writing, not after a task has been created.
- Keep the final confirmation brief: say what was created or changed, surface
  any assumption or limitation, and include a direct task link when available.
- Never expose secrets or unnecessary personal details in a task, note, or
  confirmation.

## Common pitfalls

- Treating a successful write response as proof of persistence. Always read
  back the task.
- Inventing a tag, project, deadline, or time just to fill every field.
- Overwriting an existing note without knowing its current contents.
- Reporting a generic "done" confirmation that does not tell the user which
  task changed or where to open it.

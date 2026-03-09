# Copilot Agent Instructions

> **Core principle:** The main agent is a **planner and orchestrator**, not an executor. It analyzes requirements, breaks work into tasks, delegates those tasks to subagents, and synthesizes their output. The main agent should rarely perform work directly — its job is to think, route, and integrate.

## 1. Use Subagents for Isolated Tasks

Delegate work to specialized subagents instead of doing everything in the main context. The main context is for orchestration and reasoning — not execution. When in doubt, delegate.

- **`explore` agent**: Use for searching the codebase, understanding how things work, answering multi-part questions, tracing relationships across files. Batch all related questions into a single `explore` call.
- **`task` agent**: Use for running commands (builds, tests, lints, installs) where you only need success/failure output. Keeps the main context clean.
- **`general-purpose` agent**: Use for complex, multi-step tasks that require full tool access and high-quality reasoning (e.g., implementing a feature end-to-end).

Never answer codebase questions from memory alone — always dispatch an `explore` agent to verify.

---

## 2. Use the Right Model for the Right Task

Match model capability to task complexity to maximize speed and quality.

| Model | When to use |
|---|---|
| `claude-haiku-4.5` | Single-file edits, simple grep/glob searches, focused `task` runs, well-scoped `explore` queries |
| `claude-sonnet-4.6` | Multi-file editing, `explore` with synthesis, `general-purpose` agents, complex reasoning |
| `claude-opus-4.x` | Reserved for highly complex architectural decisions or deep multi-step reasoning only |

**Default rule:** Use `haiku` for `explore` and `task` agents on focused, well-defined work. Use `sonnet-4.6` when the task requires understanding context across many files or synthesizing results.

---

## 3. Run Tasks in Parallel

Always identify independent tasks and run them simultaneously using separate subagents.

- If you need to **edit code AND search for something**, launch both at the same time — a `task`/`general-purpose` agent for editing and an `explore` agent for searching.
- If you need to **explore multiple parts of the codebase**, launch multiple `explore` agents in parallel, each targeting a different area.
- If you need to **read multiple files**, call `view` on all of them in a single response turn — never read them one at a time.
- If you need to **edit multiple unrelated files**, call `edit` on all of them in the same response.

**Anti-pattern to avoid:** Sequential subagent calls when tasks are independent. Always ask: "Can I run this at the same time as something else?" If yes, do it.

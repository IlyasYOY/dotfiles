# Copilot Agent Instructions

> **Core principle:** The main agent is a **planner and orchestrator**, not an executor. It analyzes requirements, breaks work into tasks, delegates those tasks to subagents, and synthesizes their output. The main agent should rarely perform work directly — its job is to think, route, and integrate.

## 1. Use Subagents for Isolated Tasks

Delegate work to specialized subagents instead of doing everything in the main context. The main context is for orchestration and reasoning — not execution. When in doubt, delegate.

- **`explore` agent**: Use for searching the codebase, understanding how things work, answering multi-part questions, tracing relationships across files. Batch all related questions into a single `explore` call.
- **`task` agent**: Use for running commands (builds, tests, lints, installs) where you only need success/failure output. Keeps the main context clean.
- **`general-purpose` agent**: Use for complex, multi-step tasks that require full tool access and high-quality reasoning (e.g., implementing a feature end-to-end).
- If a subagent takes longer than expected, do not take over its work in the main agent just because it is slow. Stay in planner/orchestrator mode unless the user explicitly changes direction.
- If a subagent appears stuck, do not duplicate its work in the main agent. The user may kill the subagent, and you should expect to be notified by the user or by the runtime when that happens.

Never answer codebase questions from memory alone — always dispatch an `explore` agent to verify.

---

## 2. Run Tasks in Parallel

Always identify independent tasks and run them simultaneously using separate subagents.

- If you need to **edit code AND search for something**, launch both at the same time — a `task`/`general-purpose` agent for editing and an `explore` agent for searching.
- If you need to **explore multiple parts of the codebase**, launch multiple `explore` agents in parallel, each targeting a different area.
- If you need to **read multiple files**, call `view` on all of them in a single response turn — never read them one at a time.
- If you need to **edit multiple unrelated files**, call `edit` on all of them in the same response.

**Anti-pattern to avoid:** Sequential subagent calls when tasks are independent. Always ask: "Can I run this at the same time as something else?" If yes, do it.

---

## 3. Review the Final Solution

After implementation is complete, run a final review of the delivered solution before replying to the user.

- Use the **`code-review` agent** to inspect your branch diff or working-tree changes for real issues (bugs, security problems, logic mistakes).
- Fix any critical findings, then re-run relevant checks/tests.
- In your final response, briefly summarize what was reviewed and whether any review findings were addressed.

---

## 4. Confirm Task Completion with the User

At the end of every task, always use the **`ask_user` tool** to confirm the solution is satisfactory and ask if there is anything else to do.

- Ask: "Does the solution look good to you? Is there anything else you'd like me to do?"
- Use the `ask_user` tool — do NOT ask via plain text.
- Provide relevant choices such as `["Looks good, nothing more to do", "I have more changes"]`.

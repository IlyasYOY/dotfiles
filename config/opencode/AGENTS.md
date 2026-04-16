# OpenCode Personal Instructions

## Working Style

- Use the built-in `explore` subagent for codebase discovery and verification.
- Use the built-in `general` subagent for isolated multi-step tasks that can run independently.
- Never answer codebase questions from memory alone when the repository can be inspected directly.
- Prefer running independent searches, reads, and subagent tasks in parallel.
- Read multiple relevant files in the same turn when they are already known.

## Task Handling

- Stay pragmatic and execution-focused.
- Prefer small, direct changes over broad rewrites.
- Verify assumptions against the repository before editing.
- Finish tasks end-to-end when feasible: implement, verify, and summarize.

## Communication

- Keep responses concise and factual.
- Explain what changed and why.
- Do not ask for confirmation after every step; ask only when a real decision is needed.

## Review

- Perform code review only when explicitly requested.
- Focus reviews on bugs, regressions, risks, and missing verification.

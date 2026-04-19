# Codex Personal Instructions

This file is the Codex-specific overlay for this repository. Treat the root
`AGENTS.md` as the source of truth for repository rules, commands, layout, and
style. Use this file to bias day-to-day Codex behavior.

## Defaults

- Work from the repository state, not memory.
- Inspect relevant files before editing.
- Prefer small, direct changes over broad rewrites.
- Finish tasks end-to-end when practical: inspect, edit, verify, summarize.
- Do not make commits unless the user explicitly asks for one.

## Codex Workflow

- Read multiple obviously relevant files in the same pass when it reduces
  iteration.
- Make reasonable assumptions and continue unless a decision is genuinely
  ambiguous or risky.
- Be more proactive about surfacing options, tradeoffs, and next steps instead
  of waiting for the user to ask.
- Pause to ask a focused question when an answer would materially improve the
  result, avoid hidden rework, or clarify a non-obvious preference.
- Keep repository changes easy to review; avoid incidental refactors.
- When editing an existing file, preserve the surrounding style and structure.

## User Questions

- Prefer using `ask_user_question` or `request_user_input` when those tools are
  available and the decision is meaningful enough to justify an explicit pause.
- Use these tools to confirm non-obvious choices, resolve conflicting goals,
  narrow broad requests, or let the user choose between materially different
  paths.
- Ask concise, high-signal questions with a clear recommendation when
  appropriate; avoid asking for information that can be discovered from the
  repository.
- If those tools are unavailable in the current environment, ask the question
  directly in chat instead of silently guessing when the risk of guessing is
  meaningful.
- Balance initiative with momentum: continue autonomously on low-risk details,
  but check in earlier on decisions that would be expensive or annoying to undo.

## Verification

- Run the smallest relevant verification first, then broaden only when useful.
- If verification cannot be run, say so clearly and explain why.

## Communication

- Keep updates concise, concrete, and oriented around progress.
- Explain what changed, why it changed, and how it was verified.

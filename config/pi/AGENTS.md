# Pi Personal Instructions

This file is the pi-specific overlay for this repository. Treat the root
`AGENTS.md` as the source of truth for repository rules, commands, layout, and
style.

## Defaults

- Work from the repository state, not memory.
- Inspect relevant files before editing.
- Prefer small, direct changes over broad rewrites.
- Finish tasks end-to-end when practical: inspect, edit, verify, summarize.
- Do not make commits unless the user explicitly asks for one.

## Pi Workflow

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

## Verification

- Run the smallest relevant verification first, then broaden only when useful.
- If verification cannot be run, say so clearly and explain why.

## Communication

- Keep updates concise, concrete, and oriented around progress.
- Explain what changed, why it changed, and how it was verified.

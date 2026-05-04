# Codex Personal Instructions

- Do not make commits unless the user explicitly asks for one.
- Explain what changed, why it changed, and how it was verified.

- Delegation and Subagents
  - Prefer delegating substantial multi-step work to subagents instead of doing
    everything in the main thread.
  - Before delegating, split the work into vertical slices. Each slice should
    produce a coherent user-visible behavior, repository outcome, or independently
    reviewable change.
  - Define each slice with its goal, owned files or modules, expected output, and
    verification command or check.
  - Use subagents for slices that can proceed independently, and run multiple
    subagents in parallel when their write scopes do not overlap.
  - Keep orchestration, final integration and user communication in the
    main thread.
  - Do not delegate work that requires immediate main-thread decisions, sensitive
    credentials, destructive operations, or tightly coupled edits that are likely
    to conflict.
  - Tell each subagent that it is not alone in the codebase, must not revert
    changes made by others, and must adapt to concurrent changes.
  - Require each subagent to report changed files, important decisions,
    verification results, and any unresolved risks.
  - After subagents finish, inspect their outputs, resolve integration issues, run
    the final checks, and explain what changed, why it changed, and how it was
    verified.
  - Model Selection
    - Prefer Spark coding models for coding tasks, especially implementation,
      focused refactors, test fixes, and verification subagents.
    - Use a stronger non-Spark model only when the task needs deeper architecture,
      ambiguous product reasoning, high-risk security or data handling, or the user
      explicitly asks for a different model.


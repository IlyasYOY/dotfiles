---
name: setup-codex
description: >-
  Configure ~/.codex/config.toml from this dotfiles repository. Use only when
  the user explicitly asks to run setup-codex, reconcile Codex settings, or
  migrate the former script-managed Codex config.
---

# Setup Codex

Reconcile the user's Codex config with the preferences stored in
`references/config.toml` while preserving unrelated settings.

## Workflow

1. Confirm the current Git root contains this skill at
   `.agents/skills/setup-codex/SKILL.md`. Stop if it does not; this workflow is
   intentionally limited to the dotfiles repository.
2. Read the repository `AGENTS.md`, this file, and `references/config.toml`.
3. Resolve the reference placeholders:
   - `{{HOME}}`: the user's home directory.
   - `{{DOTFILES_DIR}}`: the physical dotfiles repository root.
   - `{{KB_DIR}}`: `$ILYASYOY_KB_STORE_DIR`, or `~/Projects/kb-store` when it
     is unset.
   - `{{PERSONAL_PROJECTS_DIR}}`: the parent directory of the dotfiles root.
4. Resolve the target as `$CODEX_HOME/config.toml`, defaulting `CODEX_HOME` to
   `~/.codex`. Inspect the target and its symlink status without writing.
5. Parse the target as TOML. Treat a missing target as an empty config. If it
   is unreadable, invalid, or a symlink to an unexpected location, report the
   problem and ask the user what to do; never replace it automatically.
6. Detect legacy lines matching
   `## start ilyasyoy codex ... ##` or `## end ilyasyoy codex ... ##`.
   Propose removing only those comment lines. Never delete a marker span,
   because unrelated settings may have been inserted inside it.
7. Compare every leaf in the rendered reference with the target. Treat arrays
   as single values and group differences as `root`, `tui`, `notice`,
   `sandbox`, `features`, `memories`, `mcp`, and `projects`. Preserve every
   target key not present in the reference.
8. Show a concise redacted summary containing missing, differing, and legacy
   marker changes. Never print unknown values or values whose key or content
   looks like a token, password, key, credential, authorization header, or
   secret.
9. Ask the user to choose one of: apply all groups, select groups, or cancel.
   If groups are selected, ask only about those groups. Do not write before a
   choice is explicit.
10. Before the first write, request approval for writing under `CODEX_HOME`.
    Create `config.toml.YYYYMMDDHHMMSS.bak` with metadata preserved. If the
    target is missing, state that no backup is possible.
11. Apply only the confirmed groups and marker-line cleanup. Keep root keys
    before TOML tables, retain comments where practical, and preserve all
    unrelated tables and runtime-generated settings. Do not use the old
    dotfiles setup helpers.
12. Parse the result again, then run
    `codex doctor --summary --no-color --ascii`. If validation fails, stop,
    show the failure, and offer to restore the backup; do not restore or make
    further edits without confirmation.
13. Report changed groups, the backup path, validation result, and that a new
    Codex session may be required. If there is no diff, report that without
    creating a backup.

## Safety

- Configure only `config.toml`; do not alter auth, sessions, plugins, skills,
  memories, rules, or other files under `CODEX_HOME`.
- Never request or expose secret values. MCP entries contain environment
  variable names only.
- Do not commit repository changes.

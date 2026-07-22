---
name: setup-opencode
description: >-
  Configure ~/.config/opencode/opencode.json from this dotfiles repository.
  Use only when the user explicitly asks to run setup-opencode, reconcile
  OpenCode settings, or migrate the former script-managed OpenCode config.
---

# Setup OpenCode

Reconcile the user's OpenCode config with the preferences stored in
`references/opencode.json` while preserving unrelated settings.

## Workflow

1. Confirm the current Git root contains this skill at
   `.agents/skills/setup-opencode/SKILL.md`. Stop if it does not; this workflow
   is intentionally limited to the dotfiles repository.
2. Read the repository `AGENTS.md`, this file, and
   `references/opencode.json`.
3. Resolve the target as
   `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json`. Inspect the
   target and its symlink status without writing.
4. Parse the reference and target as strict JSON objects. Treat a missing
   target as an empty object. If the target is unreadable, invalid JSON, JSONC,
   or not an object, report the problem and ask the user what to do; never
   replace it automatically.
5. Handle symlinks before comparing values:
   - If the target links to this repository's former
     `config/opencode/opencode.json`, propose replacing it with a regular local
     file. Preserve a readable resolved file as the backup; for a dangling
     link, preserve the link itself and record its target.
   - If it links anywhere else, report the target and ask the user what to do.
     Never replace an unknown symlink automatically.
6. Compare every leaf in the reference with the target. Treat arrays as single
   values and group differences as `core`, `permissions`, `command`, `agent`,
   and `mcp`. Preserve every target key not present in the reference.
7. Show a concise redacted summary containing missing and differing values
   plus any symlink migration. Never print unknown values or values whose key
   or content looks like a token, password, key, credential, authorization
   header, or secret.
8. Ask the user to choose one of: apply all groups, select groups, or cancel.
   If groups are selected, ask only about those groups. Do not write before a
   choice is explicit.
9. Before the first write, request approval to modify the global OpenCode
   config. Create `opencode.json.YYYYMMDDHHMMSS.bak` with metadata preserved.
   If the target is missing, state that no backup is possible.
10. Apply only the confirmed groups and symlink migration. Deep-merge objects,
    replace only confirmed arrays or scalar leaves, format with two spaces and
    a final newline, and preserve all unrelated user, work, provider, and MCP
    settings. Do not use the old dotfiles setup helpers.
11. Validate with `jq empty` and then run the real runtime check without
    printing the resolved config:
    `OPENCODE_CONFIG=<target> opencode debug config --pure >/dev/null`.
    If validation fails, stop, show the failure, and offer to restore the
    backup; do not restore or make further edits without confirmation.
12. Report changed groups, the backup path, validation result, and that
    OpenCode must be restarted because config is loaded at startup. If there is
    no diff, report that without creating a backup.

## Safety

- Configure only `opencode.json`; do not alter sessions, auth, plugins,
  commands, skills, databases, logs, or other OpenCode state.
- Never request or expose secret values. Keep secret references in `{env:...}`
  form and verify only whether required environment variables are present.
- Do not commit repository changes.

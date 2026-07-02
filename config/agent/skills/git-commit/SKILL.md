---
name: git-commit
description: >
  Draft or create one Conventional Commit from staged changes. Use when the
  user asks for a commit message, commit title/body, or a local commit for
  already staged Git changes.
---

# Git Commit

Draft one Conventional Commit from the staged diff while preserving the
repository's recent commit style. Create a commit only when the user explicitly
asks for one.

## Workflow

1. Inspect only staged changes:
   - `git diff --cached --stat`
   - `git diff --cached --name-status`
   - `git diff --cached`

   Completion criterion: every staged path and every meaningful staged behavior
   is understood; unstaged changes are ignored unless the user asked for them.

2. Read recent commit style:
   - Prefer `python3 -B config/agent/skills/git-commit/scripts/commit_context.py --repo . --limit 12`.
   - If the helper is unavailable, use `git log` for recent subjects.

   Completion criterion: the draft can match observed type/scope/ticket/body
   style instead of a generic Conventional Commit template.

3. Draft the title:
   - Format: `<type>(<scope>): <summary>` or `<type>: <summary>`.
   - If recent commits use a ticket prefix, preserve it:
     `{ticket}: <type>(<scope>): <summary>`.
   - Use a scope only when changed paths and history make it clear.
   - Keep the summary short, specific, lowercase, and imperative.

4. Draft the body:
   - Explain why the change exists, not the file list.
   - Use the user's stated reason when available.
   - If the motivation is not discoverable from the prompt, conversation, diff,
     or helper output, ask before finalizing.

5. Preserve staged content:
   - Do not stage, unstage, edit, format, or include unstaged work unless the
     user separately asks for that work.

Completion criterion for a message-only request: return the exact title and
body, and state that no commit was created.

## Commit Execution

When the user explicitly asks to commit:

1. Confirm the final title and body.
2. Offer relevant project checks before committing unless they already ran in
   this turn; use documented commands from `AGENTS.md`, `README.md`, `Makefile`,
   package scripts, or CI config.
3. If checks are requested and fail, stop before committing and report the
   failure.
4. Request approval before Git index or commit operations when required by the
   environment.
5. Run `git commit` with the approved message.

Completion criterion for a commit request: report the commit hash, exact message
used, checks run or skipped, and any remaining local changes.

## Helper Script

Run the helper from the repository root:

```bash
python3 -B config/agent/skills/git-commit/scripts/commit_context.py --repo . --limit 12
```

Useful options:

- `--diff-source staged` is the default and inspects only staged changes.
- `--diff-source all` includes staged and unstaged changes.
- `--limit N` controls recent commit count.
- `--reason "..."` records an explicit reason.
- `--ticket "TICKET-123"` overrides branch ticket detection.
- `--json` emits structured output.

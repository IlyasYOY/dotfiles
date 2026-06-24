---
name: git-commit
description: Draft or create one Conventional Commit from staged Git changes. Use when an agent needs a commit message, commit title/body, or local commit for an already staged change while preserving the repository's recent commit style.
---

# Git Commit

## Overview

Use this skill to draft a Conventional Commit title and body from staged
changes, oriented around the repository's recent commit style.

Only run `git commit` when the user explicitly asks to commit and approval for
the Git operation has been granted. Otherwise, return the message for review.
Treat `$git-commit staged` as a request to draft a message for staged changes
only; do not create a commit unless the user also explicitly says to commit.

## Workflow

1. Inspect staged changes only:
   - `git diff --cached --stat`
   - `git diff --cached --name-status`
   - `git diff --cached`
2. Analyze recent project commits before drafting:
   - Prefer `scripts/commit_context.py --repo . --limit 12`.
   - If the script is unavailable, read recent commits with `git log`.
 3. Draft a short Conventional Commit title:
    - Format: `<type>(<scope>): <summary>` or `<type>: <summary>`.
    - **If recent commits use a ticket prefix** (e.g., `ISSUE-12345: chore: ...`),
      include it: `{ticket}: <type>(<scope>): <summary>`.
    - Keep the summary short, specific, lowercase, and imperative.
    - Use a scope only when recent history and changed paths make it clear.
4. Write a body that explains why the change was done:
   - The body should explain motivation, not repeat the file list.
   - If the reason is already clear from the user request, conversation, or
     staged diff, use that reason directly.
   - If the reason is not obvious, ask the user for clarification before
     finalizing the commit message.
5. Preserve existing staged content:
   - Do not stage, unstage, format, or edit files unless the user separately
     asks for that work.
   - Do not include unstaged changes in the message unless the user explicitly
     asks for all local changes.

## Commit Execution

When the user explicitly asks to commit:

1. Confirm the final commit title and body.
2. Ask whether to run the project's quality checks before committing:
   - Prefer `request_user_input` when it is available, with choices to run
     checks or skip them.
   - Recommend running checks unless the user already ran the relevant checks
     in the current turn.
   - Use documented project commands from sources such as `AGENTS.md`,
     `README.md`, `Makefile`, package scripts, or CI config.
   - If `request_user_input` is unavailable, ask a concise plain-text question.
   - If the user chooses checks and they fail, stop before committing and report
     the failure.
3. Request approval before running any Git index or commit operation if the
   environment requires it.
4. Run `git commit` with the approved message.
5. Report the commit hash and the exact message used.

If the user asks only for a message, do not commit.

## Helper Script

Run the helper from the repository root:

```bash
python3 -B config/agent/skills/git-commit/scripts/commit_context.py --repo . --limit 12
```

Useful options:

- `--diff-source staged` is the default and inspects only staged changes.
- `--diff-source all` includes staged and unstaged changes.
- `--limit N` controls how many recent commits are analyzed.
- `--reason "..."` records an explicit reason so the helper does not flag the
  reason as missing.
- `--ticket "TICKET-123"` overrides the Jira ticket prefix auto-detected from
  the branch name.
- `--json` emits structured output for automation.

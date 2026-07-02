---
name: git-commit-split
description: >
  Split a dirty Git worktree into semantic Conventional Commits. Use when the
  user asks to categorize local changes, plan commit groups, partial-stage
  mixed work, create multiple commits, or report remaining artifacts.
---

# Git Commit Split

Turn a mixed local worktree into reviewable intent-based commit groups. Keep
tests and docs with the behavior they validate or explain.

## Workflow

1. Lock scope before touching the index:
   - Restate the requested scope as `staged`, `unstaged`, `all changes`, or
     `plan only`.
   - Treat `git-commit-split unstaged` literally.
   - If the user did not explicitly allow commits, return a grouping plan and
     do not stage anything.

   Completion criterion: the allowed mutation boundary is explicit.

2. Inventory the worktree:
   - Run `git status --short --untracked-files=all`.
   - Inspect staged, unstaged, untracked, deleted, and renamed changes.
   - Read files needed to classify intent.
   - Identify generated artifacts, logs, caches, editor files, and local-only
     outputs.

   Completion criterion: every changed path is assigned to a group, excluded as
   generated/local, or marked unresolved with a reason.

3. Build semantic groups:
   - Group by behavior or purpose, not path alone.
   - Keep tests and docs with their behavior.
   - Separate unrelated formatting, pure renames, and tool metadata.
   - Plan partial staging when one file contains multiple intents.

   Completion criterion: each group can be described by one commit title and no
   group contains unrelated behavior.

4. Decide whether to commit:
   - For categorize/plan requests, return the grouping plan only.
   - For explicit commit requests, proceed group by group after required
     approvals.
   - Ask only when grouping depends on product intent that cannot be inferred
     from diffs.

5. Stage and commit one group at a time:
   - Stage only current group paths or hunks.
   - Inspect `git diff --cached --name-status`, `git diff --cached --stat`, and
     the cached diff before committing.
   - Use `git-commit` when available for local message style.
   - Run `git status --short --untracked-files=all` after each commit.

   Completion criterion: each commit contains only its group, and remaining
   changes still match the plan.

6. Verify and report:
   - Run targeted non-mutating checks when practical.
   - Never run rewriting formatters unless requested.
   - Report commit hashes/titles, verification, and remaining uncommitted files.

## Grouping Heuristics

- Feature or fix code plus tests is one `feat` or `fix` commit.
- Setup scripts plus docs for that setup are one scoped commit.
- A new reusable skill, script, or tool can be one `feat` commit.
- Small keybinding, launcher, or preference changes are usually `chore`.
- Rename-only changes are `refactor` or `chore`, depending on the file.
- Deleted obsolete helpers belong with the replacement that made them obsolete.

## Safety Rules

- Never push unless explicitly asked.
- Never discard, revert, or overwrite user changes to simplify grouping.
- Preserve pre-existing staged content unless asked to reorganize it.
- Request approval before Git index writes or commits when required.
- Remove generated artifacts only when created during the current task or
  obviously disposable; otherwise leave them uncommitted and report them.

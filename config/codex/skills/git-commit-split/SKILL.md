---
name: git-commit-split
description: Split a dirty Git worktree into multiple semantically coherent Conventional Commits. Use when Codex needs to inspect staged, unstaged, deleted, renamed, or untracked changes; categorize local changes; group them by functional intent; stage each group; create one commit per behavior/config/docs/test change; or cleanly report remaining uncommitted artifacts.
---

# Git Commit Split

## Overview

Use this skill to turn a mixed local Git worktree into a short series of
reviewable commits. Optimize for intent: each commit should represent one
functional change, with its tests and docs included when they explain or verify
that change.

## Workflow

1. State Git intent before grouping or staging:
   - Restate the requested scope as `staged`, `unstaged`, `all changes`, or
     `plan only`.
   - Treat `git-commit-split unstaged` literally: limit the workflow to
     unstaged changes unless the user explicitly includes staged or untracked
     work.
   - If the prompt does not explicitly permit commits, return a grouping plan
     first and wait for explicit commit permission before staging.

2. Inventory before staging:
   - Run `git status --short --untracked-files=all`.
   - Inspect `git diff --cached --name-status`, `git diff --name-status`,
     `git diff --stat`, and relevant full diffs.
   - List untracked files with `git ls-files --others --exclude-standard` and
     read the files that may be committed.
   - Identify generated artifacts such as logs, caches, build output, or local
     editor files. Do not commit them unless clearly intentional.

3. Build semantic groups:
   - Group by behavior or purpose, not by path alone.
   - Keep tests with the behavior they validate.
   - Keep docs with the feature, setup flow, or interface they document.
   - Treat pure renames, formatting-only changes, and tool metadata updates as
     separate commits when they are unrelated to behavior.
   - If one file contains changes for multiple groups, plan partial staging
     explicitly and verify the cached diff before committing.

4. Decide whether to commit:
   - If the user asked only to categorize or plan, return the grouping plan and
     do not mutate the index.
   - If the user explicitly asked to commit, proceed group by group after any
     required approvals.
   - Ask a concise question only when the grouping depends on intent that cannot
     be discovered from the repo.

5. Stage and commit one group at a time:
   - Stage only the paths or hunks for the current group.
   - Inspect `git diff --cached --name-status`, `git diff --cached --stat`,
     and the cached diff before committing.
   - Use the `git-commit` skill when available to preserve local commit
     style; otherwise follow recent `git log` subjects.
   - Write a short Conventional Commit title and a body that explains why the
     change exists.
   - Run `git status --short --untracked-files=all` after each commit to confirm
     the next group is isolated.

6. Verify and report:
   - Run targeted checks that match the changed areas when practical.
   - Prefer non-mutating checks before committing; never run formatters that
     rewrite files unless the user asked for formatting.
   - Finish with the commit hashes, exact commit titles, verification performed,
     and any remaining uncommitted files.

## Grouping Heuristics

- Feature code plus its tests is usually one `feat` or `fix` commit.
- Setup scripts plus documentation for that setup are usually one scoped commit.
- A new reusable skill, script, or tool can be its own `feat` commit.
- Small keybinding, app launcher, or preference changes are usually `chore`.
- Rename-only changes are usually `refactor` or `chore`, depending on the file.
- Deleted obsolete helpers belong with the replacement that made them obsolete.

## Safety Rules

- Never push unless the user explicitly asks.
- Never discard, revert, or overwrite user changes to make grouping easier.
- Preserve pre-existing staged content unless the user asked to reorganize it.
- Request approval before Git index writes or commits when the environment
  requires it.
- Remove generated artifacts only when they were created during the current
  task or are obviously disposable; otherwise leave them uncommitted and report
  them.

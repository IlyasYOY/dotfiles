---
name: git-commit
description: >
  Draft, group, or create Conventional Commits. Use when the user asks for a
  commit message, commit title/body, a local commit from staged changes,
  categorizing local changes, partial staging mixed work, multiple semantic
  commits, or remaining artifacts.
---

# Git Commit

Draft Conventional Commit messages and organize local Git changes while
preserving the repository's recent commit style. Stage or commit only when the
user explicitly asks.

## Workflow

1. Choose the branch:
   - Use `staged single commit` for a commit message, title/body, or one local
     commit from already staged changes.
   - Use `grouping plan` for categorizing, splitting, partial staging, or
     reporting dirty worktree changes without explicit commit approval.
   - Use `multi-commit execution` only when the user explicitly asks to create
     multiple commits.

   Completion criterion: the response path and allowed mutation boundary are
   explicit before any staging or commit operation.

## Staged Single Commit

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

   Completion criterion: the title follows observed repository style and every
   type, scope, ticket, and wording choice is supported by the diff or history.

4. Draft the body:
   - Explain why the change exists, not the file list.
   - Use the user's stated reason when available.
   - If the motivation is not discoverable from the prompt, conversation, diff,
     or helper output, ask before finalizing.

   Completion criterion: the body explains discoverable motivation, or the user
   was asked for the missing motivation before finalizing.

5. Preserve staged content:
   - Do not stage, unstage, edit, format, or include unstaged work unless the
     user separately asks for that work.

   Completion criterion: the staged diff is unchanged except for user-approved
   staging, unstaging, editing, or formatting.

Completion criterion for a message-only request: return the exact title and
body, and state that no commit was created.

## Grouping Plan

Turn a mixed local worktree into reviewable intent-based commit groups.

1. Lock scope before touching the index:
   - Restate the requested scope as `staged`, `unstaged`, `all changes`, or
     `plan only`.
   - Treat split-command aliases with `unstaged` literally as `unstaged`.
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
   - Keep tests and docs with the behavior they validate or explain.
   - Separate unrelated formatting, pure renames, and tool metadata.
   - Plan partial staging when one file contains multiple intents.

   Completion criterion: each group can be described by one commit title and no
   group contains unrelated behavior.

4. Decide whether to commit:
   - For categorize or plan requests, return the grouping plan only.
   - For explicit commit requests, proceed group by group after required
     approvals.
   - Ask only when grouping depends on product intent that cannot be inferred
     from diffs.

   Completion criterion: the next action is either a returned grouping plan or
   an approved group-by-group commit run.

## Commit Execution

When the user explicitly asks to commit:

1. Confirm the final title and body, or the final list of commit groups.

   Completion criterion: the exact message or group list is fixed before Git
   mutation begins.

2. Offer relevant project checks before committing unless they already ran in
   this turn; use documented commands from `AGENTS.md`, `README.md`, `Makefile`,
   package scripts, or CI config.

   Completion criterion: checks were offered, already run, or explicitly
   skipped before committing.

3. If checks are requested and fail, stop before committing and report the
   failure.

   Completion criterion: no commit is created after a failed requested check.

4. Request approval before Git index or commit operations when required by the
   environment.

   Completion criterion: required approval is granted before index or commit
   mutation, or the environment does not require it.

5. For a staged single commit, run `git commit` with the approved message.

   Completion criterion: the staged single commit contains exactly the approved
   staged diff and message.

6. For multi-commit execution, repeat for each group:
   - Stage only current group paths or hunks.
   - Inspect `git diff --cached --name-status`, `git diff --cached --stat`, and
     the cached diff before committing.
   - Draft the message through the staged single commit branch.
   - Run `git status --short --untracked-files=all` after each commit.

   Completion criterion: each commit contains only its group, and remaining
   changes still match the plan.

Completion criterion for a commit request: report each commit hash and exact
message used, checks run or skipped, and any remaining local changes.

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

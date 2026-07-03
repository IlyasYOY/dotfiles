---
name: kb-store-note
description: Explicit creator for the per-branch project note README in kb-store.
---

# Create Branch Note

Ensure the per-branch project note exists in kb-store for the current project
and branch. Idempotent: a pre-existing README is never modified.

Store a note this way when you want a persistent, per-branch scratchpad for the
current project — session notes, decisions, MR status, command recipes — that
survives across sessions and stays scoped to one branch. For a throwaway
thought or a daily log, use `diary/` or a zettel note instead (see the layout
below); this skill is only the branch README.

## Steps

1. Set `KB_STORE="$HOME/Projects/kb-store"`. If that path does not exist, stop
   and tell the user kb-store is missing.

   Completion criterion: `KB_STORE` exists on disk.

2. Resolve the mirrored project folder.
   - When inside a git worktree, `$PWD` may be a sibling directory with a
     suffix (e.g. `dotfiles-SOME-1234` next to the main worktree
     `dotfiles`). Always derive the project path from the **main worktree**
     so that all feature branches of one repo share one kb-store folder.
   - `MAIN_WORKTREE=$(git worktree list --porcelain 2>/dev/null | head -1 | cut -d' ' -f2)`
     — first entry in `git worktree list` output is the main (primary)
     worktree; empty when not a git repo.
   - `PROJECT_PATH="${MAIN_WORKTREE:-$PWD}"` — fall back to `$PWD` when not in
     a git repo.
   - `MIRRORED=${PROJECT_PATH#"$HOME"}` — the `$HOME`-relative path with a
     leading slash (e.g. `/Projects/IlyasYOY/dotfiles`).
   - `FOLDER=${MIRRORED#/}` — drop the leading slash for the kb-store folder
     (e.g. `Projects/IlyasYOY/dotfiles`).
   - Stop if `PROJECT_PATH` is not under `$HOME`: that is when
     `"$MIRRORED"` equals `"$PROJECT_PATH"` (nothing stripped), or `MIRRORED`
     is empty (`PROJECT_PATH` is `$HOME`), or `MIRRORED` is `/`.

   Completion criterion: `FOLDER` is a non-empty relative path derived from a
   project path under `$HOME`, resolved via the main worktree when in a git
   repo.

3. Resolve the branch folder name.
   - `BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo master)`; if
     empty (not a git repo), use `master`.
   - `BRANCH_FOLDER=branch-${BRANCH//\//-}` — every `/` becomes a hyphen
     (e.g. `feature/auth` -> `branch-feature-auth`).

   Completion criterion: `BRANCH_FOLDER` is `branch-` plus the branch name
   with every `/` replaced by `-`.

4. Ensure the branch folder exists.
   - `mkdir -p "$KB_STORE/$FOLDER/$BRANCH_FOLDER"`.

   Completion criterion: the branch folder exists.

5. Ensure `README.md` exists; never clobber.
   - Target: `$KB_STORE/$FOLDER/$BRANCH_FOLDER/README.md`.
   - If it already exists, leave it untouched.
   - Otherwise create it with this starter (the values come from the prior
     steps; the basename is `${PROJECT_PATH##*/}`, derived from the main
     worktree, not `$PWD`):

      ```markdown
      # ${PROJECT_PATH##*/} — $BRANCH

      Notes for `$MIRRORED` on branch `$BRANCH`.
      ```

   Completion criterion: `README.md` exists, either pre-existing and
   untouched or newly created with the starter above.

6. Report the absolute README path and whether it was created or already
   existed.

   Completion criterion: output names the README path and its creation
   status.

## kb-store layout

kb-store (`~/Projects/kb-store`) mirrors `$HOME`: a note for
`~/Projects/IlyaYOY/dotfiles` lives at `Projects/IlyaYOY/dotfiles/`. Inside each
project, notes sit in `branch-<branch>/` folders. This skill creates the
`branch-<branch>/README.md` scratchpad for the current project and branch —
the steps above are the operational form of that rule.

The `README.md` at the kb-store root is authoritative for the path and branch
conventions. Re-read it if those rules ever disagree with the steps above.

Other areas, not touched by this skill: `diary/` holds daily session reports;
`meta/templates/` holds Obsidian note templates (daily, weekly, zettel).

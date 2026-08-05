#!/usr/bin/env bash

# projector: manage git worktrees and branches in a project setup.
#
# This file is sourced at shell startup by sh/helpers.sh. It defines a
# `projector` shell function plus private `_projector_*` helpers so that
# directory-changing commands (feature/release/fix/review/merge) persist in the
# caller's shell without needing `. projector ...`.
#
# It is written to run under both bash and zsh: no `read -p`, no
# `read -ra`, no `BASH_SOURCE`.

_projector_is_git_repo() {
    git rev-parse --git-dir >/dev/null 2>&1
}

_projector_get_project_name() {
    basename "$(git rev-parse --show-toplevel)"
}

_projector_get_default_branch() {
    if git symbolic-ref refs/remotes/origin/HEAD >/dev/null 2>&1; then
        git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
        return 0
    fi

    if git remote set-head origin --auto >/dev/null 2>&1; then
        git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
        return 0
    fi

    git branch -r | sed -n 's|origin/\(main\|master\).*|\1|p' | head -1
}

_projector_get_accumulated_prefix() {
    local project_name="$1"
    local current_dir
    local suffix

    current_dir="$(basename "$PWD")"
    if [[ "$current_dir" == "$project_name" ]]; then
        echo ""
        return 0
    fi

    suffix="${current_dir#"$project_name"-}"
    echo "${suffix}-"
}

_projector_get_main_worktree_path() {
    dirname "$(git rev-parse --path-format=absolute --git-common-dir)"
}

_projector_get_branch_worktree_path() {
    local branch_name="$1"
    local line
    local current_path=""
    local current_branch=""

    while IFS= read -r line; do
        case "$line" in
            worktree\ *)
                current_path="${line#worktree }"
                current_branch=""
                ;;
            branch\ refs/heads/*)
                current_branch="${line#branch refs/heads/}"
                if [[ "$current_branch" == "$branch_name" ]]; then
                    echo "$current_path"
                    return 0
                fi
                ;;
            "")
                current_path=""
                current_branch=""
                ;;
        esac
    done < <(git worktree list --porcelain)

    return 1
}

# Return 0 if <path> should not be copied as an ignored item.
_projector_should_skip_ignored_path() {
    local path="$1"
    local -a skip_dirs=(".git" "node_modules" "vendor" "build" "dist" "target" ".venv" "__pycache__" ".gradle")
    local extra="${PROJECTOR_CLONE_IGNORED_EXTRA:-}"
    local part dir rest item

    if [[ -n "$extra" ]]; then
        rest="$extra"
        while [[ -n "$rest" ]]; do
            item="${rest%%,*}"
            skip_dirs+=("$item")
            [[ "$item" == "$rest" ]] && break
            rest="${rest#*,}"
        done
    fi

    rest="$path"
    while [[ -n "$rest" ]]; do
        part="${rest%%/*}"
        for dir in "${skip_dirs[@]}"; do
            if [[ "$part" == "$dir" ]]; then
                return 0
            fi
        done
        [[ "$part" == "$rest" ]] && break
        rest="${rest#*/}"
    done

    return 1
}

# List ignored paths present in <repo_root> (respects global and repo gitignore).
_projector_get_ignored_paths() {
    local repo_root="$1"

    while IFS= read -r line; do
        if [[ "$line" == "!! "* ]]; then
            echo "${line#!! }"
        fi
    done < <(git -C "$repo_root" status --porcelain --ignored=matching --untracked-files=all 2>/dev/null)
}

# Copy ignored files/directories from source_dir into target_dir.
_projector_copy_ignored_files() {
    local source_dir="$1"
    local target_dir="$2"
    local item
    local target_path
    local copied=0
    local skipped=0

    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        [[ -e "$source_dir/$item" ]] || continue

        if _projector_should_skip_ignored_path "$item"; then
            ((skipped++))
            continue
        fi

        target_path="$target_dir/$item"
        if [[ -e "$target_path" ]]; then
            ((skipped++))
            continue
        fi

        mkdir -p "$(dirname "$target_path")"
        cp -a "$source_dir/$item" "$target_path" || {
            echo "Warning: failed to copy ignored item: $item"
            continue
        }
        ((copied++))
    done < <(_projector_get_ignored_paths "$source_dir")

    echo "Cloned ignored items: copied=$copied skipped=$skipped"
}

_projector_create_prefixed_worktree() {
    local branch_prefix="$1"
    local name="$2"
    local clone_ignored="${3:-true}"
    local project_name
    local accumulated_prefix
    local worktree_path
    local worktree_suffix
    local branch_name
    local current_branch
    local existing_branch
    local main_worktree_path

    project_name="$(_projector_get_project_name)"
    accumulated_prefix="$(_projector_get_accumulated_prefix "$project_name")"
    branch_name="${branch_prefix}/${name}"
    current_branch="$(git branch --show-current)"

    if [[ -z "$current_branch" ]]; then
        echo "Error: Unable to determine the current branch"
        return 1
    fi

    worktree_suffix="${name}"
    if [[ "$branch_prefix" != "feature" ]]; then
        worktree_suffix="${branch_prefix}-${name}"
    fi

    worktree_path="../${project_name}-${accumulated_prefix}${worktree_suffix}"

    if [[ -d "$worktree_path" ]]; then
        if ! git -C "$worktree_path" rev-parse --git-dir >/dev/null 2>&1; then
            echo "Error: Directory '$worktree_path' already exists but is not a git worktree"
            return 1
        fi

        existing_branch="$(git -C "$worktree_path" branch --show-current)"
        if [[ "$existing_branch" != "$branch_name" ]]; then
            echo "Error: Directory '$worktree_path' is on branch '$existing_branch', expected '$branch_name'"
            return 1
        fi

        echo "Warning: Worktree directory '$worktree_path' already exists. Reusing it."
        window_name="${project_name}-${branch_name//\//-}"
        if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
            tmux new-window -c "$worktree_path" -n "$window_name"
            echo "Opened tmux window '$window_name' at $worktree_path"
            return 0
        fi
        cd "$worktree_path" || return 1
        return 0
    fi

    if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "Creating branch '$branch_name' from '$current_branch'..."
        git branch "$branch_name" "$current_branch" || return 1
    fi

    echo "Creating worktree '$worktree_path' for branch '$branch_name'..."
    git worktree add "$worktree_path" "$branch_name" || return 1

    if [[ "$clone_ignored" == "true" ]]; then
        main_worktree_path="$(_projector_get_main_worktree_path)"
        _projector_copy_ignored_files "$main_worktree_path" "$worktree_path"
    fi

    window_name="${project_name}-${branch_name//\//-}"
    if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
        tmux new-window -c "$worktree_path" -n "$window_name"
        echo "Opened tmux window '$window_name' at $worktree_path"
    else
        cd "$worktree_path" || return 1
        echo "Switched to worktree: $PWD"
    fi
}

_projector_merge_current_branch() {
    local source_branch
    local default_branch
    local target_worktree

    source_branch="$(git branch --show-current)"
    if [[ -z "$source_branch" ]]; then
        echo "Error: Unable to determine the current branch"
        return 1
    fi

    default_branch="$(_projector_get_default_branch)"
    if [[ -z "$default_branch" ]]; then
        echo "Error: Unable to determine the default branch"
        return 1
    fi

    if [[ "$source_branch" == "$default_branch" ]]; then
        echo "Error: Already on the default branch '$default_branch'"
        return 1
    fi

    if ! target_worktree="$(_projector_get_branch_worktree_path "$default_branch")"; then
        target_worktree="$(_projector_get_main_worktree_path)"
    fi

    echo "Switching to '$default_branch' worktree at '$target_worktree'..."
    cd "$target_worktree" || return 1

    if [[ "$(git branch --show-current)" != "$default_branch" ]]; then
        git checkout "$default_branch" || return 1
    fi

    echo "Merging '$source_branch' into '$default_branch'..."
    git merge "$source_branch"
}

_projector_print_usage() {
    echo "projector: A tool for managing git worktrees and branches in a project setup."
    echo ""
    echo "Usage: projector [global options] <command> [args]"
    echo ""
    echo "Global options:"
    echo "  --no-clone-ignored      Do not copy ignored files/directories from the main worktree when creating a worktree."
    echo "  --clone-ignored         Copy ignored files/directories from the main worktree (default)."
    echo ""
    echo "Commands:"
    echo "  pull                    Pull the latest changes from the default branch of the 'origin' remote."
    echo "  sync                    Pull the latest changes from the default branch of the 'upstream' remote (if configured)."
    echo "  feature <name>          Create a new git worktree for a feature branch and switch to it."
    echo "  release <name>          Create a new git worktree for a release branch and switch to it."
    echo "  fix <name>              Create a new git worktree for a fix branch and switch to it."
    echo "  chore <name>            Create a new git worktree for a chore branch and switch to it."
    echo "  refactor <name>         Create a new git worktree for a refactor branch and switch to it."
    echo "  ci <name>               Create a new git worktree for a ci branch and switch to it."
    echo "  docs <name>             Create a new git worktree for a docs branch and switch to it."
    echo "  review <branch-name>    Check out an existing branch by name in a new worktree and switch to it."
    echo "  merge                   Switch to the default branch worktree and merge the current branch into it."
    echo ""
    echo "Notes:"
    echo "  - This tool assumes you're in a git repository with 'origin' remote configured."
    echo "  - projector is a shell function; directory-changing commands (feature/release/fix/review/merge)"
    echo "    persist in the current shell automatically. No need to source anything."
    echo ""
    echo "Examples:"
    echo "  projector pull                       # Update from origin's default branch"
    echo "  projector feature auth               # Create worktree for 'feature/auth' and switch to it"
    echo "  projector release 1.2.0              # Create worktree for 'release/1.2.0' and switch to it"
    echo "  projector fix typo                   # Create worktree for 'fix/typo' and switch to it"
    echo "  projector review feature/auth        # Check out existing 'feature/auth' branch and switch to it"
    echo "  projector --no-clone-ignored feature auth  # Same, but skip copying ignored files"
    echo "  projector merge                      # Switch to the default branch worktree and merge the current branch"
}

_projector_main() {
    local command
    local default_branch
    local args=()
    local CLONE_IGNORED="true"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-clone-ignored)
                CLONE_IGNORED="false"
                shift
                ;;
            --clone-ignored)
                CLONE_IGNORED="true"
                shift
                ;;
            -h | --help)
                _projector_print_usage
                return 0
                ;;
            -*)
                echo "Error: Unknown option '$1'"
                return 1
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    set -- "${args[@]}"

    if [[ $# -lt 1 ]]; then
        _projector_print_usage
        return 1
    fi

    command="$1"
    shift

    if ! _projector_is_git_repo; then
        echo "Error: Not in a git repository"
        return 1
    fi

    case "$command" in
        pull)
            if [[ $# -ne 0 ]]; then
                echo "Error: 'pull' takes no arguments"
                return 1
            fi

            default_branch="$(_projector_get_default_branch)"
            if [[ -z "$default_branch" ]]; then
                echo "Error: Unable to determine the default branch"
                return 1
            fi

            echo "Pulling from origin/$default_branch..."
            git pull origin "$default_branch"
            ;;
        sync)
            if [[ $# -ne 0 ]]; then
                echo "Error: 'sync' takes no arguments"
                return 1
            fi

            if ! git remote | grep -q upstream; then
                echo "Warning: No 'upstream' remote found, skipping sync"
                return 0
            fi

            default_branch="$(_projector_get_default_branch)"
            if [[ -z "$default_branch" ]]; then
                echo "Error: Unable to determine the default branch"
                return 1
            fi

            echo "Syncing from upstream/$default_branch..."
            git pull upstream "$default_branch"
            ;;
        feature | release | fix | chore | refactor | ci | docs)
            if [[ $# -ne 1 ]]; then
                echo "Error: '$command' requires exactly one argument: <name>"
                return 1
            fi

            _projector_create_prefixed_worktree "$command" "$1" "$CLONE_IGNORED"
            ;;
        review)
            if [[ $# -ne 1 ]]; then
                echo "Error: 'review' requires exactly one argument: <branch-name>"
                return 1
            fi

            local branch_name project_name main_worktree current_dir
            local worktree_suffix worktree_path existing_branch window_name

            branch_name="$1"
            project_name="$(_projector_get_project_name)"
            main_worktree="$(_projector_get_main_worktree_path)"
            current_dir="$(basename "$PWD")"

            if [[ "$current_dir" != "$project_name" ]]; then
                echo "Error: 'review' must be run from the main worktree ($main_worktree)"
                return 1
            fi

            if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
                echo "Branch '$branch_name' not found locally, fetching from origin..."
                git fetch origin "$branch_name:$branch_name" || {
                    echo "Error: Failed to fetch branch '$branch_name' from origin"
                    return 1
                }
            fi

            worktree_suffix="review-${branch_name//\//-}"
            worktree_path="../${project_name}-${worktree_suffix}"

            if [[ -d "$worktree_path" ]]; then
                if ! git -C "$worktree_path" rev-parse --git-dir >/dev/null 2>&1; then
                    echo "Error: Directory '$worktree_path' already exists but is not a git worktree"
                    return 1
                fi

                existing_branch="$(git -C "$worktree_path" branch --show-current)"
                if [[ "$existing_branch" != "$branch_name" ]]; then
                    echo "Error: Directory '$worktree_path' is on branch '$existing_branch', expected '$branch_name'"
                    return 1
                fi

                echo "Warning: Worktree directory '$worktree_path' already exists. Reusing it."
                window_name="${project_name}-${branch_name//\//-}"
                if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
                    tmux new-window -c "$worktree_path" -n "$window_name"
                    echo "Opened tmux window '$window_name' at $worktree_path"
                    return 0
                fi
                cd "$worktree_path" || return 1
                return 0
            fi

            echo "Creating worktree '$worktree_path' for review branch '$branch_name'..."
            git worktree add "$worktree_path" "$branch_name" || return 1

            if [[ "$CLONE_IGNORED" == "true" ]]; then
                _projector_copy_ignored_files "$main_worktree" "$worktree_path"
            fi

            window_name="${project_name}-${branch_name//\//-}"
            if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
                tmux new-window -c "$worktree_path" -n "$window_name"
                echo "Opened tmux window '$window_name' at $worktree_path"
            else
                cd "$worktree_path" || return 1
                echo "Switched to worktree: $PWD"
            fi
            ;;
        merge)
            if [[ $# -ne 0 ]]; then
                echo "Error: 'merge' takes no arguments"
                return 1
            fi

            _projector_merge_current_branch
            ;;
        *)
            echo "Error: Unknown command '$command'"
            echo "Available commands: pull, sync, feature <name>, release <name>, fix <name>, chore <name>, refactor <name>, ci <name>, docs <name>, review <branch-name>, merge"
            return 1
            ;;
    esac
}

projector() {
    _projector_main "$@"
}

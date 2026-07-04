#!/usr/bin/env bash

# shellcheck source=/dev/null
source "$ILYASYOY_DOTFILES_DIR/sh/projector.sh"

# tms runs fzf for me to search through tmux sessions and choose one I want to
# use. works in and out of the tmux.
tms() {
    selected_session=$(tmux list-sessions -F "#{session_name}" | fzf --prompt="Select tmux session: "); 
    if [ -n "$selected_session" ]; then 
        tmux attach -t "$selected_session" || tmux switch-client -t "$selected_session"; 
    fi
}

pass-fzf() {
    local password_store_dir selected

    password_store_dir="${PASSWORD_STORE_DIR:-$HOME/.password-store}"

    if ! command -v pass >/dev/null 2>&1; then
        printf "pass-fzf: pass is not available\n" >&2
        return 1
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        printf "pass-fzf: fzf is not available\n" >&2
        return 1
    fi

    if [ ! -d "$password_store_dir" ]; then
        printf "pass-fzf: password store not found: %s\n" "$password_store_dir" >&2
        return 1
    fi

    selected=$(
        (
            cd "$password_store_dir" || exit
            find . -type f -name "*.gpg" -print
        ) \
            | sed "s#^\./##; s#\.gpg\$##" \
            | sort \
            | fzf --prompt="pass> "
    ) || return 0

    [ -n "$selected" ] || return 0
    pass -c "$selected"
}

### multimedia conversion ###

convert-webm-to-mp4() {
    for webmfile in *.webm; do 
        ffmpeg -n -i "$webmfile" "$webmfile.mp4";
    done
}

convert-webp-to-png() {
    for webpfile in *.webp; do 
        ffmpeg -n -i "$webpfile" "$webpfile.png";
    done
}

_ai_cli() {
    if command -v codex >/dev/null 2>&1; then
        printf "codex\n"
        return 0
    fi

    if command -v opencode >/dev/null 2>&1; then
        printf "opencode\n"
        return 0
    fi

    return 1
}

ai() {
    local tool
    if ! tool=$(_ai_cli); then
        printf "ai: neither codex nor opencode is available\n" >&2
        return 1
    fi

    "$tool" "$@"
}

ai-resume() {
    if command -v codex >/dev/null 2>&1; then
        codex resume "$@"
        return 0
    fi

    if command -v opencode >/dev/null 2>&1; then
        opencode --continue "$@"
        return 0
    fi

    printf "ai-resume: neither codex nor opencode is available\n" >&2
    return 1
}

ai-kb() {
    local kb_dir="${ILYASYOY_KB_STORE_DIR:-$HOME/Projects/kb-store}"
    local tool

    if [ ! -d "$kb_dir" ]; then
        printf "ai-kb: kb-store directory not found: %s\n" "$kb_dir" >&2
        return 1
    fi

    if ! tool=$(_ai_cli); then
        printf "ai-kb: neither codex nor opencode is available\n" >&2
        return 1
    fi

    (
        cd "$kb_dir" || exit
        "$tool" "$@"
    )
}

alias codexr="codex resume"
alias codex-spark="codex --model gpt-5.3-codex-spark"
alias codexrl="codex resume --last"
alias opencoder="opencode --continue"

codex-kb() {
    local kb_dir="${ILYASYOY_KB_STORE_DIR:-$HOME/Projects/kb-store}"

    if [ ! -d "$kb_dir" ]; then
        printf "codex-kb: kb-store directory not found: %s\n" "$kb_dir" >&2
        return 1
    fi

    (
        cd "$kb_dir" || exit
        codex "$@"
    )
}

opencode-kb() {
    local kb_dir="${ILYASYOY_KB_STORE_DIR:-$HOME/Projects/kb-store}"

    if [ ! -d "$kb_dir" ]; then
        printf "opencode-kb: kb-store directory not found: %s\n" "$kb_dir" >&2
        return 1
    fi

    (
        cd "$kb_dir" || exit
        opencode "$@"
    )
}

nvim-kb() {
    local kb_dir="${ILYASYOY_KB_STORE_DIR:-$HOME/Projects/kb-store}"

    if [ ! -d "$kb_dir" ]; then
        printf "nvim-kb: kb-store directory not found: %s\n" "$kb_dir" >&2
        return 1
    fi

    (
        cd "$kb_dir" || exit
        if [ "$#" -eq 0 ]; then
            nvim .
        else
            nvim "$@"
        fi
    )
}

# _kb_main_root prints the absolute (physical) path of the main git repository
# root for the current directory. For a linked worktree (e.g. a projector
# feature workspace at ../<project>-<suffix>) this resolves to the parent repo
# root so that notes map to the main project folder. Falls back to the physical
# $PWD when not in a git repository or when resolution fails.
_kb_main_root() {
    local common abs_common

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        pwd -P
        return 0
    fi

    common=$(git rev-parse --git-common-dir 2>/dev/null)
    if [ -z "$common" ]; then
        pwd -P
        return 0
    fi

    abs_common=$(cd "$common" 2>/dev/null || exit; pwd -P)
    if [ -z "$abs_common" ]; then
        pwd -P
        return 0
    fi

    dirname "$abs_common"
}

# _kb_home_phy prints the physical form of $HOME (resolving symlinks) so it can
# be compared against the physical paths returned by _kb_main_root.
_kb_home_phy() {
    local phy
    phy=$(cd "$HOME" 2>/dev/null && pwd -P) || phy="$HOME"
    printf '%s\n' "$phy"
}

kb-link() {
    local kb_dir="${ILYASYOY_KB_STORE_DIR:-$HOME/Projects/kb-store}"
    local main_root rel_path branch safe_branch note_dir

    if [ ! -d "$kb_dir" ]; then
        printf "kb-link: kb-store directory not found: %s\n" "$kb_dir" >&2
        return 1
    fi

    ln -sfnv "$kb_dir" ".kb-store"

    main_root=$(_kb_main_root)
    rel_path="${main_root#"$(_kb_home_phy)"}"

    if [ -z "$rel_path" ]; then
        printf "kb-link: already in HOME; skipping project path\n" >&2
        return 0
    fi

    if [ "$rel_path" = "$main_root" ]; then
        printf "kb-link: %s is not under HOME; skipping project path\n" "$main_root" >&2
        return 0
    fi

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch=$(git branch --show-current)
    fi
    [ -z "$branch" ] && branch="master"

    safe_branch=$(printf "%s" "$branch" | tr "/" "-")
    note_dir="$kb_dir$rel_path/branch-$safe_branch"
    mkdir -p "$note_dir"

    if [ ! -f "$note_dir/README.md" ]; then
        {
            printf "# %s — %s\n\n" "${main_root##*/}" "$branch"
            printf "Notes for \`%s\` on branch \`%s\`.\n" "$rel_path" "$branch"
        } >"$note_dir/README.md"
        printf "kb-link: seeded %s\n" "$note_dir/README.md"
    fi
}

kb-note() {
    local kb_dir="${ILYASYOY_KB_STORE_DIR:-$HOME/Projects/kb-store}"
    local main_root rel_path branch safe_branch note_dir

    if [ ! -d "$kb_dir" ]; then
        printf "kb-note: kb-store directory not found: %s\n" "$kb_dir" >&2
        return 1
    fi

    main_root=$(_kb_main_root)
    rel_path="${main_root#"$(_kb_home_phy)"}"

    if [ -z "$rel_path" ]; then
        printf "kb-note: already in HOME; no project path\n" >&2
        return 1
    fi

    if [ "$rel_path" = "$main_root" ]; then
        printf "kb-note: %s is not under HOME; no project path\n" "$main_root" >&2
        return 1
    fi

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch=$(git branch --show-current)
    fi
    [ -z "$branch" ] && branch="master"

    safe_branch=$(printf "%s" "$branch" | tr "/" "-")
    note_dir="$kb_dir$rel_path/branch-$safe_branch"
    mkdir -p "$note_dir"

    (
        cd "$note_dir" || exit
        if [ "$#" -eq 0 ]; then
            "${EDITOR:-nvim}" "README.md"
        else
            "${EDITOR:-nvim}" "$@"
        fi
    )
}

# with-retry runs a command and retries it on failure with a fixed delay
# between attempts. Up to RETRY_MAX_ATTEMPTS tries (default 20) with
# RETRY_DELAY_SEC seconds (default 1) between them.
#
#   with-retry curl -fsS https://example.com
#   RETRY_DELAY_SEC=2 RETRY_MAX_ATTEMPTS=5 with-retry make test
with-retry() {
    if [ "$#" -eq 0 ]; then
        printf "with-retry: no command given\n" >&2
        return 2
    fi

    local delay="${RETRY_DELAY_SEC:-1}"
    local max_attempts="${RETRY_MAX_ATTEMPTS:-20}"
    local attempt=1
    local rc=0

    if ! [ "$delay" -ge 0 ] 2>/dev/null; then
        printf "with-retry: invalid RETRY_DELAY_SEC=%s\n" "$delay" >&2
        return 2
    fi

    if ! [ "$max_attempts" -gt 0 ] 2>/dev/null; then
        printf "with-retry: invalid RETRY_MAX_ATTEMPTS=%s\n" "$max_attempts" >&2
        return 2
    fi

    while [ "$attempt" -le "$max_attempts" ]; do
        rc=0
        "$@" || rc=$?
        if [ "$rc" -eq 0 ]; then
            return 0
        fi

        if [ "$attempt" -lt "$max_attempts" ]; then
            printf "with-retry: attempt %d/%d failed (exit %d); retrying in %ss\n" \
                "$attempt" "$max_attempts" "$rc" "$delay" >&2
            sleep "$delay"
        fi

        attempt=$((attempt + 1))
    done

    printf "with-retry: gave up after %d attempts (last exit %d)\n" \
        "$max_attempts" "$rc" >&2
    return "$rc"
}

if [ -n "${ZSH_VERSION:-}" ] && case $- in *i*) true ;; *) false ;; esac; then
    _codex_shell_command_zsh() {
        if [ -z "${BUFFER:-}" ]; then
            return 0
        fi

        if ! command -v codex >/dev/null 2>&1; then
            zle -M "codex: command not found"
            return 1
        fi

        local old_buffer="$BUFFER"
        local output_file
        local error_file
        local generated_command
        local error_message
        local model="${CODEX_SHELL_COMMAND_MODEL:-gpt-5.3-codex-spark}"
        local prompt

        output_file=$(mktemp "${TMPDIR:-/tmp}/codex-shell-command.XXXXXX") || {
            zle -M "codex: failed to create temp file"
            return 1
        }
        error_file=$(mktemp "${TMPDIR:-/tmp}/codex-shell-command-error.XXXXXX") || {
            rm -f "$output_file"
            zle -M "codex: failed to create temp file"
            return 1
        }

        prompt="Convert the user's request into exactly one shell command.
Return only the command text. Do not use markdown. Do not explain.
Do not run tools or execute the command. The command must be safe to review
before the user presses Enter.

Current working directory: $PWD
User request: $old_buffer"

        BUFFER="$old_buffer  [codex...]"
        zle -I
        zle redisplay

        if ! codex exec \
            --model "$model" \
            --ephemeral \
            --skip-git-repo-check \
            --sandbox read-only \
            --color never \
            --output-last-message "$output_file" \
            "$prompt" </dev/null >/dev/null 2>"$error_file"; then
            BUFFER="$old_buffer"
            error_message=$(sed -n '1p' "$error_file")
            rm -f "$output_file" "$error_file"
            if [ -z "$error_message" ]; then
                error_message="failed to generate command"
            fi
            zle -M "codex: $error_message"
            zle redisplay
            return 1
        fi

        generated_command=$(cat "$output_file")
        rm -f "$output_file" "$error_file"

        if [ -z "$generated_command" ]; then
            BUFFER="$old_buffer"
            zle -M "codex: generated empty command"
            zle redisplay
            return 1
        fi

        BUFFER="$generated_command"
        zle end-of-line
    }

    _opencode_shell_command_zsh() {
        if [ -z "${BUFFER:-}" ]; then
            return 0
        fi

        if ! command -v opencode >/dev/null 2>&1; then
            zle -M "opencode: command not found"
            return 1
        fi

        local old_buffer="$BUFFER"
        local output_file
        local error_file
        local generated_command
        local error_message
        local prompt

        output_file=$(mktemp "${TMPDIR:-/tmp}/opencode-shell-command.XXXXXX") || {
            zle -M "opencode: failed to create temp file"
            return 1
        }
        error_file=$(mktemp "${TMPDIR:-/tmp}/opencode-shell-command-error.XXXXXX") || {
            rm -f "$output_file"
            zle -M "opencode: failed to create temp file"
            return 1
        }

        prompt="Current working directory: $PWD
User request: $old_buffer"

        BUFFER="$old_buffer  [opencode...]"
        zle -I
        zle redisplay

        if ! opencode run --command shell-command "$prompt" >"$output_file" 2>"$error_file"; then
            BUFFER="$old_buffer"
            error_message=$(sed -n '1p' "$error_file")
            rm -f "$output_file" "$error_file"
            if [ -z "$error_message" ]; then
                error_message="failed to generate command"
            fi
            zle -M "opencode: $error_message"
            zle redisplay
            return 1
        fi

        generated_command=$(awk 'NF { print }' "$output_file")
        rm -f "$output_file" "$error_file"

        if [ -z "$generated_command" ]; then
            BUFFER="$old_buffer"
            zle -M "opencode: generated empty command"
            zle redisplay
            return 1
        fi

        BUFFER="$generated_command"
        zle end-of-line
    }

    _ai_shell_command_zsh() {
        if command -v codex >/dev/null 2>&1; then
            _codex_shell_command_zsh
            return $?
        fi

        if command -v opencode >/dev/null 2>&1; then
            _opencode_shell_command_zsh
            return $?
        fi

        zle -M "ai: neither codex nor opencode is available"
        return 1
    }

    zle -N _codex_shell_command_zsh
    zle -N _opencode_shell_command_zsh
    zle -N _ai_shell_command_zsh
    bindkey '\ee' _ai_shell_command_zsh
fi

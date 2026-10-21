#!/usr/bin/env bash

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

ai() {
    if ! command -v codex >/dev/null 2>&1; then
        printf "ai: codex is not available\n" >&2
        return 1
    fi

    codex "$@"
}

ai-resume() {
    if command -v codex >/dev/null 2>&1; then
        codex resume "$@"
        return 0
    fi

    printf "ai-resume: codex is not available\n" >&2
    return 1
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

    zle -N _codex_shell_command_zsh
    bindkey '\ee' _codex_shell_command_zsh
fi

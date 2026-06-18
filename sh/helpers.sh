#!/usr/bin/env bash

# tms runs fzf for me to search through tmux sessions and choose one I want to
# use. works in and out of the tmux.
tms() {
    selected_session=$(tmux list-sessions -F "#{session_name}" | fzf --prompt="Select tmux session: "); 
    if [ -n "$selected_session" ]; then 
        tmux attach -t "$selected_session" || tmux switch-client -t "$selected_session"; 
    fi
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

alias opencoder="opencode --continue"

opencode-notes() {
    local notes_dir="${ILYASYOY_NOTES_DIR:-$HOME/Projects/IlyasYOY/notes-wiki}"

    if [ ! -d "$notes_dir" ]; then
        printf "opencode-notes: notes directory not found: %s\n" "$notes_dir" >&2
        return 1
    fi

    (
        cd "$notes_dir" || exit
        opencode "$@"
    )
}

nvim-notes() {
    local notes_dir="${ILYASYOY_NOTES_DIR:-$HOME/Projects/IlyasYOY/notes-wiki}"

    if [ ! -d "$notes_dir" ]; then
        printf "nvim-notes: notes directory not found: %s\n" "$notes_dir" >&2
        return 1
    fi

    (
        cd "$notes_dir" || exit
        if [ "$#" -eq 0 ]; then
            nvim .
        else
            nvim "$@"
        fi
    )
}

if [ -n "${ZSH_VERSION:-}" ] && case $- in *i*) true ;; *) false ;; esac; then
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

    zle -N _opencode_shell_command_zsh
    bindkey '\ee' _opencode_shell_command_zsh
fi

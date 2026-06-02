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

alias codexr="codex resume"
alias codex-spark="codex --model gpt-5.3-codex-spark"
alias codexrl="codex resume --last"

codex-notes() {
    codex -C "$HOME/Projects/IlyasYOY/notes-wiki" 
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

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

### aichat ###

# aichat can generate shell command by text.
# this is not correct: https://github.com/sigoden/aichat/blob/main/scripts/shell-integration/integration.zsh.
# fix is here: https://github.com/sigoden/aichat/issues/1231.
_aichat_zsh() {
    if [[ -n "$BUFFER" ]]; then
        local _old=$BUFFER
        BUFFER+="⌛"
        zle -I && zle redisplay
        BUFFER=$(command aichat --code -r '%shell%' "$_old")
        zle end-of-line
    fi
}
zle -N _aichat_zsh
bindkey '\ee' _aichat_zsh

# aichat-review-diff review the diff and puts it in STDOUT. It can be used
# later to be posted somewhere.
aichat-review-diff() {
    local diff_command="${1:-"git diff"}"
    local diff_output=$(bash -c "$diff_command")
    echo "Generated diff output." >&2
    local overview_output=$(echo "$diff_output" | aichat --role %diff-overview% "${@:2}")
    echo "Generated overview output." >&2
    local comments_output=$(echo "$diff_output" | aichat --role %diff-comments% "${@:2}")
    echo "Generated comments output." >&2

    echo "## Overview\n"
    local main_output_overview=$(echo "$overview_output" | perl -0777 -pe 's/<think>.*?<\/think>//sg')
    echo "$main_output_overview"
    echo "\n## Comments\n"
    echo "<details><summary>Click to expand comments</summary>\n"
    local main_output_comments=$(echo "$comments_output" | perl -0777 -pe 's/<think>.*?<\/think>//sg')
    echo "$main_output_comments"
    echo "\n</details>"

    if [[ "$overview_output" == *"<think>"* ]]; then
        local think_output_overview=$(echo "$overview_output" | perl -0777 -ne 'print "$1\n" while /<think>(.*?)<\/think>/gs')
    else
        local think_output_overview=""
    fi
    if [[ "$comments_output" == *"<think>"* ]]; then
        local think_output_comments=$(echo "$comments_output" | perl -0777 -ne 'print "$1\n" while /<think>(.*?)<\/think>/gs')
    else
        local think_output_comments=""
    fi
    # Display thinking output if it exists
    if [[ -n "$think_output_overview" || -n "$think_output_comments" ]]; then
        echo "\n## Thinking Output\n"
        if [[ -n "$think_output_overview" ]]; then
            echo "<details><summary>Overview thinking</summary>\n"
            echo "$think_output_overview"
            echo "\n</details>"
        fi
        if [[ -n "$think_output_comments" ]]; then
            echo "<details><summary>Comments thinking</summary>\n"
            echo "$think_output_comments"
            echo "\n</details>"
        fi
    fi
}


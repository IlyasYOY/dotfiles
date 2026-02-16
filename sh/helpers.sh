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

### opencode ###
_opencode_zsh() {
    if [[ -n "$BUFFER" ]]; then
        local _old=$BUFFER
        BUFFER+="⌛"
        zle -I && zle redisplay
        BUFFER=$(command opencode run --agent 'shell-command-generator' "$_old")
        zle end-of-line
    fi
}
zle -N _opencode_zsh
bindkey '\ee' _opencode_zsh


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

alias cplt="copilot --model gpt-5-mini"
alias opncd="opencode -m github-copilot/gpt-5-mini"


### copilot ###
_copilot_zsh() {
    if [[ -n "$BUFFER" ]]; then
        local _old=$BUFFER
        BUFFER+="⌛"
        zle -I && zle redisplay
        BUFFER=$(command copilot --model gpt-5-mini --agent shell-command-generator -p "$_old")
        zle end-of-line
    fi
}
zle -N _copilot_zsh
bindkey '\ee' _copilot_zsh


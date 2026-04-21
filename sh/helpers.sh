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
alias codexrl="codex resume --last"

codex-time-manager() {
    local token

    token="$(pass singularity/token/full)" || return

    codex \
        -c 'plugins."google-calendar@openai-curated".enabled=true' \
        -c 'mcp_servers.singularity.command="node"' \
        -c "mcp_servers.singularity.args=[\"$HOME/Projects/IlyasYOY/singularity-mcp-server-2.1.1/mcp.js\",\"--baseUrl\",\"https://api.singularity-app.com\",\"--accessToken\",\"$token\",\"-n\"]" \
        -c 'mcp_servers.singularity.tools.getNote.approval_mode="approve"' \
        -c 'mcp_servers.singularity.tools.getProject.approval_mode="approve"' \
        -c 'mcp_servers.singularity.tools.getHabit.approval_mode="approve"' \
        -c 'mcp_servers.singularity.tools.getTask.approval_mode="approve"' \
        -c 'mcp_servers.singularity.tools.listHabitProgress.approval_mode="approve"' \
        -c 'mcp_servers.singularity.tools.listHabits.approval_mode="approve"' \
        -c 'mcp_servers.singularity.tools.listNotes.approval_mode="approve"' \
        -c 'mcp_servers.singularity.tools.listProjects.approval_mode="approve"' \
        -c 'mcp_servers.singularity.tools.listTasks.approval_mode="approve"' \
        -c 'mcp_servers.singularity.tools.listTimeStats.approval_mode="approve"' \
        "$@"
}

codex-notes() {
    codex-time-manager -C "$HOME/Projects/IlyasYOY/notes-wiki" 
}

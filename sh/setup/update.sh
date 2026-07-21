#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$(dirname "$0")/helpers.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/codex-external-skills.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/mac.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/raspberry-pi.sh"

update_local_repos() {
    local -a repo_paths=(
        "$PERSONAL_PROJECTS_DIR/IlyasYOY"
        "$PERSONAL_PROJECTS_DIR/detailederror"
        "$PERSONAL_PROJECTS_DIR/ffmpeg-video-chapters-parser"
        "$PERSONAL_PROJECTS_DIR/git-link.nvim"
        "$PERSONAL_PROJECTS_DIR/go-retry"
        "$PERSONAL_PROJECTS_DIR/httpservertest"
        "$PERSONAL_PROJECTS_DIR/monotask"
        "$PERSONAL_PROJECTS_DIR/remotion-projects"
        "$PERSONAL_PROJECTS_DIR/singularity-mcp"
        "$PERSONAL_PROJECTS_DIR/t-invest-mcp"
        "$PERSONAL_PROJECTS_DIR/tasks-assistant-telegram-bot"
        "$HOME/.password-store"
    )
    local plugin
    for plugin in "${PERSONAL_NVIM_PLUGIN_REPOS[@]}"; do
        repo_paths+=("$PERSONAL_PROJECTS_DIR/$plugin")
    done

    update_repo "$PERSONAL_PROJECTS_DIR/dotfiles" || true

    update_repos_parallel "${repo_paths[@]}"
}

update_repo() {
    local repo_path="$1"

    if [ -d "$repo_path/.git" ]; then
        info "Updating repository: $repo_path"
        if git -C "$repo_path" pull; then
            success "Updated $repo_path"
        else
            error "Failed to update $repo_path"
            return 1
        fi
    else
        warning "$repo_path is not a git repo"
    fi
}

update_tmux_plugins() {
    info "Updating TMUX plugins..."
    if "$HOME_DIR/.tmux/plugins/tpm/bin/update_plugins" all; then
        success "TMUX plugins updated"
    else
        error "Failed to update TMUX plugins"
    fi
}

update_go_tools() {
    info "🎯 Updating Go tools..."

    if ! command -v go >/dev/null 2>&1; then
        warning "Go is not installed; skipping Go tools update"
        return 0
    fi

    if go install github.com/IlyasYOY/monotask/cmd/monotask@latest; then
        success "monotask updated"
    else
        error "Failed to update monotask"
        return 1
    fi

    if go install github.com/IlyasYOY/singularity-mcp/cmd/singularity-mcp@latest; then
        success "singularity-mcp updated"
    else
        error "Failed to update singularity-mcp"
        return 1
    fi

    if make -C "$PERSONAL_PROJECTS_DIR/t-invest-mcp" install; then
        success "t-invest-mcp updated"
    else
        error "Failed to update t-invest-mcp"
        return 1
    fi
}

main() {
    if is_mac; then
        update_brew
        update_brew_packages
        update_brew_cask_packages
        update_mas_applications
    elif is_raspberry_pi; then
        update_raspberry_pi_system
        update_raspberry_pi_brew
        update_raspberry_pi_brew_packages
    fi

    update_local_repos
    update_external_codex_skills
    update_tmux_plugins
    update_go_tools

}

main "$@"

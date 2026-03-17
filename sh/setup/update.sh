#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$(dirname "$0")/helpers.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/mac.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/raspberry-pi.sh"

update_local_repos() {
    update_repo "$PERSONAL_PROJECTS_DIR/dotfiles"

    update_repo "$PERSONAL_PROJECTS_DIR/detailederror"
    update_repo "$PERSONAL_PROJECTS_DIR/ffmpeg-video-chapters-parser"
    update_repo "$PERSONAL_PROJECTS_DIR/IlyasYOY"
    update_repo "$PERSONAL_PROJECTS_DIR/go-retry"
    update_repo "$PERSONAL_PROJECTS_DIR/httpservertest"
    update_repo "$PERSONAL_PROJECTS_DIR/tasks-assistant-telegram-bot"
    update_repo "$PERSONAL_PROJECTS_DIR/remotion-projects"

    update_repo "$PERSONAL_PROJECTS_DIR/git-link.nvim"
    update_repo "$PERSONAL_PROJECTS_DIR/obs.nvim"
    update_repo "$PERSONAL_PROJECTS_DIR/theme.nvim"
    update_repo "$PERSONAL_PROJECTS_DIR/monotask"

    update_repo "$NOTES_DIR"

    update_repo "$HOME/.password-store"
}

update_repo() {
    local repo_path="$1"

    if [ -d "$repo_path/.git" ]; then
        info "Updating repository: $repo_path"
        if git -C "$repo_path" pull; then
            success "Updated $repo_path"
        else
            error "Failed to update $repo_path"
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
    update_tmux_plugins

}

main "$@"

#!/usr/bin/env bash

source $(dirname $0)/helpers.sh
source $(dirname $0)/mac.sh

update_nvim() {
    info "Updating Neovim plugins..."

    if confirm_update "Update Neovim plugins"; then
        nvim --headless "+Lazy! sync" +qa && success "Lazy.nvim updated" || error "Failed to update Lazy.nvim"
    fi

    info "Updating Mason tools..."

    if confirm_update "Update Mason tools"; then
        nvim --headless "+MasonToolsUpdateSync" +qa && success "Mason tools updated" || error "Failed to update Mason tools"
    fi
}

update_local_repos() {
    update_repo "$PERSONAL_PROJECTS_DIR/dotfiles"

    update_repo "$PERSONAL_PROJECTS_DIR/detailederror"
    update_repo "$PERSONAL_PROJECTS_DIR/ffmpeg-video-chapters-parser"
    update_repo "$PERSONAL_PROJECTS_DIR/IlyasYOY"
    update_repo "$PERSONAL_PROJECTS_DIR/go-retry"
    update_repo "$PERSONAL_PROJECTS_DIR/httpservertest"
    update_repo "$PERSONAL_PROJECTS_DIR/tasks-assistant-telegram-bot"

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
        git -C "$repo_path" pull && success "Updated $repo_path" || error "Failed to update $repo_path"
    else 
        warning "$repo_path is not a git repo"
    fi
}

update_tmux_plugins() {
    info "Updating TMUX plugins..."
    "$HOME_DIR/.tmux/plugins/tpm/bin/update_plugins" all && success "TMUX plugins updated" || error "Failed to update TMUX plugins"
}

main() {
    update_brew
    update_brew_packages
    update_brew_cask_packages
    update_mas_applications

    update_local_repos
    update_tmux_plugins
    update_nvim

}

main "$@"

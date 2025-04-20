#!/usr/bin/env bash

source ./helpers.sh

update_brew() {
    info "🍺 Updating Homebrew..."

    brew update && success "Brew updated" || error "Failed to update Brew"
}

update_brew_packages() {
    info "🍺 Updating Homebrew packages..."

    brew upgrade && success "Brew packages upgraded" || error "Failed to upgrade packages"
}

update_brew_cask_packages() {
    info "🍺 Updating Homebrew cask packages..."

    brew upgrade --cask && success "Brew casks upgraded" || error "Failed to upgrade casks"
}

update_mas_applications() {
    info "🍎 Updating mas applications..."

    mas upgrade && success "Mas updated" || error "Failed to update mas"
}

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
    local repos=(
        "git@github.com:IlyasYOY/obs.nvim.git:$PERSONAL_PROJECTS_DIR/obs.nvim"
        "git@github.com:IlyasYOY/coredor.nvim.git:$PERSONAL_PROJECTS_DIR/coredor.nvim"
        "git@github.com:IlyasYOY/git-link.nvim.git:$PERSONAL_PROJECTS_DIR/git-link.nvim"
        "git@github.com:IlyasYOY/Notes.git:$NOTES_DIR"
        "git@github.com:IlyasYOY/dotfiles.git:$PERSONAL_PROJECTS_DIR/dotfiles"
    )

    for repo in "${repos[@]}"; do
        local repo_url="${repo%%:*}"
        local repo_path="${repo##*:}"

        if [ -d "$repo_path/.git" ]; then
            info "Updating repository: $repo_path"
            git -C "$repo_path" pull && success "Updated $repo_path" || error "Failed to update $repo_path"
        else 
            warning "$repo_path is not a git repo"
        fi
    done
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

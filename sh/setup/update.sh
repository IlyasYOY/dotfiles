#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/sh/setup/mac.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/sh/setup/gnupg.sh"

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
        "$PERSONAL_PROJECTS_DIR/t-invest-mcp"
        "$PERSONAL_PROJECTS_DIR/tasks-assistant-telegram-bot"
    )

    if [ ! -e "$PERSONAL_PROJECTS_DIR/t-invest-mcp/.git" ]; then
        error "Required build checkout is missing: $PERSONAL_PROJECTS_DIR/t-invest-mcp"
        return 1
    fi
    update_repos_parallel "${repo_paths[@]}" || return 1
    update_repo "$HOME/.password-store" || warning "Optional password-store update failed"
}

update_repo() {
    local repo_path="$1"

    if [ -e "$repo_path/.git" ]; then
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
    setup_tmux_plugins || return 1
    if "$HOME_DIR/.tmux/plugins/tpm/bin/update_plugins" all; then
        success "TMUX plugins updated"
    else
        error "Failed to update TMUX plugins"
        return 1
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

    if make -C "$PERSONAL_PROJECTS_DIR/t-invest-mcp" install; then
        success "t-invest-mcp updated"
    else
        error "Failed to update t-invest-mcp"
        return 1
    fi
}

main() {
    if ! is_mac; then
        error "Workstation setup supports macOS only"
        return 1
    fi

    if [ ! -e "$DOTFILES_DIR/.git" ]; then
        error "Dotfiles checkout is not a Git repository: $DOTFILES_DIR"
        return 1
    fi
    update_repo "$DOTFILES_DIR"
    if is_mac; then
        if ! load_mac_brew; then
            error "Homebrew is not available; run make install to bootstrap it"
            return 1
        fi
        update_brew
        setup_mac_using_brew
        setup_mac_using_brew_cask
        update_brew_packages
        update_brew_cask_packages
    fi

    setup_gnupg
    setup_worktrunk
    update_local_repos
    "$DOTFILES_DIR/sh/setup/workbenches.sh" update
    update_tmux_plugins
    update_go_tools

}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

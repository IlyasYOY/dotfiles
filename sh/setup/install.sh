#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/sh/setup/mac.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/sh/setup/gnupg.sh"

setup_basic_directories() {
    info "📁 Creating basic directories..."
    mkdir -pv "$PERSONAL_PROJECTS_DIR" "$WORK_PROJECTS_DIR"
}

setup_my_project() {
    info "👨💻 Setting up personal projects..."

    clone_repos_parallel \
        "git@github.com:IlyasYOY/monotask.git" "$PERSONAL_PROJECTS_DIR/monotask" \
        "git@github.com:IlyasYOY/IlyasYOY.git" "$PERSONAL_PROJECTS_DIR/IlyasYOY" \
        "git@github.com:IlyasYOY/t-invest-mcp.git" "$PERSONAL_PROJECTS_DIR/t-invest-mcp"
}

setup_notes() {
    info "📝 Setting up notes..."

    mkdir -pv "$KB_DIR"
    if [ ! -d "$KB_DIR/.git" ]; then
        git -C "$KB_DIR" init
        success "Initialized kb-store git repo"
    fi
}

setup_links_to_config_files() {
    info "⚙️ Setting up config links..."
    local config_dir="$HOME/.config"
    mkdir -pv "$config_dir"
    mkdir -pv "$HOME/.gnupg"

    # Main config links
    if is_mac; then
        symlink "$DOTFILES_DIR/config/wezterm" "$config_dir/wezterm"
        symlink "$DOTFILES_DIR/config/hammerspoon" "$HOME/.hammerspoon"
    fi
    setup_gnupg || return 1

    # Git config
    mkdir -pv "$config_dir/git"
    symlink "$DOTFILES_DIR/config/.gitignore-global" "$config_dir/git/ignore"

    # Home directory links
    symlink "$DOTFILES_DIR/config/.tmux.conf" "$HOME_DIR/.tmux.conf"
    symlink "$DOTFILES_DIR/config/.vimrc" "$HOME_DIR/.vimrc"
    if is_mac; then
        symlink "$DOTFILES_DIR/config/.amethyst.yml" "$HOME_DIR/.amethyst.yml"
    fi
}

setup_platform_dependencies() {
    if is_mac; then
        setup_mac_homebrew || return 1
        setup_mac_using_brew || return 1
        setup_mac_using_brew_cask || return 1

        return 0
    fi

    warning "No platform-specific dependency bootstrap is configured for this host"
}

setup_mac_configuration() {
    if ! is_mac; then
        return 0
    fi

    if confirm_update "Apply macOS defaults"; then
        setup_mac_defaults

        if confirm_update "Restart macOS UI services"; then
            restart_mac_ui_services
        fi
    fi
}

setup_shell_rc() {
    local rc_file shell fragment legacy_line
    rc_file=$(shell_rc_file)
    shell=$(shell_name)
    info "🐚 Configuring $rc_file..."

    add_line "export ILYASYOY_DOTFILES_DIR=\"$DOTFILES_DIR\"" "$rc_file"
    add_line "source <(fzf --$shell)" "$rc_file"
    for fragment in helpers exports aliases; do
        # Earlier installations emitted unquoted source lines. Do not load twice.
        legacy_line="source \$ILYASYOY_DOTFILES_DIR/sh/$fragment.sh"
        if grep -qxF "$legacy_line" "$rc_file"; then
            continue
        fi
        add_line "source \"\$ILYASYOY_DOTFILES_DIR/sh/$fragment.sh\"" "$rc_file"
    done
}

setup_sdkman() {
    info "☕ Installing SDKMAN..."

    if [ ! -e "$HOME/.sdkman" ] && [ ! -L "$HOME/.sdkman" ]; then
        run_downloaded_installer https://get.sdkman.io bash || return 1
    fi
    require_installation_file "$HOME/.sdkman/bin/sdkman-init.sh" || return 1
    success "SDKMAN installed"

    local sdkman_config
    sdkman_config=$'export SDKMAN_DIR="$HOME/.sdkman"\n[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"'

    add_block "$(shell_rc_file)" \
        "ilyasyoy sdkman config" \
        "$sdkman_config"
}

setup_node_version_manager() {
    info "⬢ Installing fnm (Fast Node Manager)..."

    # fnm configuration
    local rc_file shell
    rc_file=$(shell_rc_file)
    shell=$(shell_name)
    local fnm_config="eval \"\$(fnm env --use-on-cd --shell $shell)\""

    add_block "$rc_file" \
        "ilyasyoy fnm config" \
        "$fnm_config"

    if ! command -v fnm >/dev/null 2>&1; then
        warning "fnm is not available in the current shell yet; install Node.js after opening a new shell"
        return 0
    fi

    eval "$(fnm env --shell bash)"

    if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
        fnm install --lts --use
        local node_version
        node_version=$(fnm current)
        if [ -n "$node_version" ]; then
            fnm default "$node_version"
        fi
        success "Node.js and npm installed with fnm"
    else
        debug "Node.js and npm already installed"
    fi
}

setup_go_version_manager() {
    info "🐹 Installing GVM..."
    if [ ! -e "$HOME/.gvm" ] && [ ! -L "$HOME/.gvm" ]; then
        run_downloaded_installer \
            https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer bash || return 1
    fi
    require_installation_file "$HOME/.gvm/scripts/gvm" || return 1
    success "GVM installed"

    # GVM configuration
    local gvm_config=$'_gvm_lazy_load() {\n    unset -f gvm\n    [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"\n    "$@"\n}\ngvm() { _gvm_lazy_load gvm "$@"; }'

    add_block "$(shell_rc_file)" \
        "ilyasyoy gvm config" \
        "$gvm_config"
}

setup_go_binaries() {
    info "🎯 Installing Go binaries..."

    if ! command -v go >/dev/null 2>&1; then
        warning "Go is not installed yet; skipping Go binary installation"
        return 0
    fi

    if go install github.com/IlyasYOY/monotask/cmd/monotask@latest; then
        success "monotask installed"
    else
        error "Failed to install monotask"
        return 1
    fi

    if make -C "$PERSONAL_PROJECTS_DIR/t-invest-mcp" install; then
        success "t-invest-mcp installed"
    else
        error "Failed to install t-invest-mcp"
        return 1
    fi
}

setup_oh_my_zsh() {
    if ! is_mac; then
        info "This is not mac, skipping Oh My Zsh installation"
        return 0
    fi

    info "🚀 Installing Oh My Zsh..."
    if [ ! -e "$HOME/.oh-my-zsh" ] && [ ! -L "$HOME/.oh-my-zsh" ]; then
        ZSH="$HOME/.oh-my-zsh" run_downloaded_installer \
            https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
            sh --unattended --keep-zshrc || return 1
    fi
    require_installation_file "$HOME/.oh-my-zsh/oh-my-zsh.sh" || return 1
    success "Oh My Zsh installed"
}

setup_git_config() {
    info "🔧 Configuring Git..."

    git config --global alias.st "status"
    git config --global alias.c "commit"
    git config --global alias.co "checkout"
    git config --global alias.lg "log --all --decorate --graph --oneline"
    git config --global diff.algorithm histogram
    git config --global core.quotePath false
}

setup_pass() {
    info "💻🔐 pass password-store..."

    clone_repo "git@github.com:IlyasYOY/password-store.git" "$HOME/.password-store/" ||
        warning "Optional password-store clone failed"
}

main() {
    if ! is_mac; then
        error "Workstation setup supports macOS only"
        return 1
    fi

    setup_basic_directories
    setup_oh_my_zsh
    setup_platform_dependencies
    setup_notes
    setup_links_to_config_files
    setup_mac_configuration
    setup_shell_rc
    setup_worktrunk
    setup_git_config
    setup_sdkman
    setup_go_version_manager
    setup_my_project
    setup_go_binaries
    setup_node_version_manager
    setup_tmux_plugins
    setup_pass

    "$DOTFILES_DIR/sh/setup/workbenches.sh" install

    success "🎉 Setup completed successfully!"
    info "Some changes might require a new shell session or system restart"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

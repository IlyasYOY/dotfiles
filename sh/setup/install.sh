#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$(dirname "$0")/helpers.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/mac.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/raspberry-pi.sh"

setup_basic_directories() {
    info "📁 Creating basic directories..."
    mkdir -pv "$PERSONAL_PROJECTS_DIR" "$WORK_PROJECTS_DIR"
}

setup_my_project() {
    info "👨💻 Setting up personal projects..."

    clone_repos_parallel \
        "git@github.com:IlyasYOY/obs.nvim.git" "$PERSONAL_PROJECTS_DIR/obs.nvim" \
        "git@github.com:IlyasYOY/coredor.nvim.git" "$PERSONAL_PROJECTS_DIR/coredor.nvim" \
        "git@github.com:IlyasYOY/git-link.nvim.git" "$PERSONAL_PROJECTS_DIR/git-link.nvim" \
        "git@github.com:IlyasYOY/theme.nvim.git" "$PERSONAL_PROJECTS_DIR/theme.nvim" \
        "git@github.com:IlyasYOY/monotask.git" "$PERSONAL_PROJECTS_DIR/monotask"
    clone_repo "git@github.com:IlyasYOY/exectest.git" "$PERSONAL_PROJECTS_DIR/monotask" || true
}

setup_notes() {
    info "📝 Setting up notes..."

    clone_repos_parallel \
        "git@github.com:IlyasYOY/notes-wiki.git" "$NOTES_DIR" \
        "git@github.com:IlyasYOY/Legacy-Notes.git" "$LEGACY_NOTES_DIR"
}

setup_links_to_config_files() {
    info "⚙️ Setting up config links..."
    local config_dir="$HOME/.config"
    mkdir -pv "$config_dir"
    mkdir -pv "$HOME/.gnupg"

    # Main config links
    symlink "$DOTFILES_DIR/config/nvim" "$config_dir/nvim"
    symlink "$DOTFILES_DIR/config/nvim-minimal" "$config_dir/nvim-minimal"
    if is_mac; then
        symlink "$DOTFILES_DIR/config/wezterm" "$config_dir/wezterm"
        symlink "$DOTFILES_DIR/config/hammerspoon" "$HOME/.hammerspoon"
    fi
    symlink "$DOTFILES_DIR/config/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
    setup_mac_pinentry_defaults
    if command -v gpgconf >/dev/null 2>&1; then
        gpgconf --kill gpg-agent && gpgconf --launch gpg-agent && debug "restart gpg-agent"
    else
        debug "gpgconf is not available yet, skipping gpg-agent restart"
    fi


    # Git config
    mkdir -pv "$config_dir/git"
    symlink "$DOTFILES_DIR/config/.gitignore-global" "$config_dir/git/ignore"

    # Home directory links
    symlink "$DOTFILES_DIR/config/.golangci.yml" "$HOME_DIR/.golangci.yml"
    symlink "$DOTFILES_DIR/config/.tmux.conf" "$HOME_DIR/.tmux.conf"
    symlink "$DOTFILES_DIR/config/.vimrc" "$HOME_DIR/.vimrc"
    if is_mac; then
        symlink "$DOTFILES_DIR/config/.amethyst.yml" "$HOME_DIR/.amethyst.yml"
    fi
}

setup_platform_dependencies() {
    if is_mac; then
        setup_mac_using_brew
        setup_mac_using_brew_cask
        setup_mac_using_app_store

        if confirm_update "Apply macOS defaults"; then
            setup_mac_defaults

            if confirm_update "Restart macOS UI services"; then
                restart_mac_ui_services
            fi
        fi

        return 0
    fi

    if is_raspberry_pi; then
        setup_raspberry_pi
        return 0
    fi

    warning "No platform-specific dependency bootstrap is configured for this host"
}



setup_shell_rc() {
    local rc_file
    rc_file=$(shell_rc_file)

    if is_raspberry_pi; then
        info "🐚 Configuring .bashrc..."
    else
        info "🐚 Configuring .zshrc..."
    fi

    local lines=(
        "export ILYASYOY_DOTFILES_DIR=\"$DOTFILES_DIR\""
        "source \$ILYASYOY_DOTFILES_DIR/sh/helpers.sh"
        "source \$ILYASYOY_DOTFILES_DIR/sh/exports.sh"
        "source \$ILYASYOY_DOTFILES_DIR/sh/aliases.sh"
    )

    if is_raspberry_pi; then
        lines=(
            "export ILYASYOY_DOTFILES_DIR=\"$DOTFILES_DIR\""
            "source <(fzf --bash)"
            "source \$ILYASYOY_DOTFILES_DIR/sh/helpers.sh"
            "source \$ILYASYOY_DOTFILES_DIR/sh/exports.sh"
            "source \$ILYASYOY_DOTFILES_DIR/sh/aliases.sh"
        )
    else
        lines=(
            "export ILYASYOY_DOTFILES_DIR=\"$DOTFILES_DIR\""
            "source <(fzf --zsh)"
            "source \$ILYASYOY_DOTFILES_DIR/sh/helpers.sh"
            "source \$ILYASYOY_DOTFILES_DIR/sh/exports.sh"
            "source \$ILYASYOY_DOTFILES_DIR/sh/aliases.sh"
        )
    fi

    for line in "${lines[@]}"; do
        add_line "$line" "$rc_file"
    done
}

setup_sdkman() {
    info "☕ Installing SDKMAN..."

    if [ ! -d "$HOME/.sdkman" ]; then
        curl -s "https://get.sdkman.io" | bash
        success "SDKMAN installed"
    else
        debug "SDKMAN already installed"
    fi

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
    if [ ! -d "$HOME/.gvm" ]; then
        bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
        # Source GVM immediately
        # shellcheck source=/dev/null
        [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

        success "GVM installed"
    else 
        debug "GVM already installed"
    fi

    # GVM configuration
    local gvm_config=$'_gvm_lazy_load() {\n    unset -f gvm\n    [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"\n    "$@"\n}\ngvm() { _gvm_lazy_load gvm "$@"; }'

    add_block "$(shell_rc_file)" \
        "ilyasyoy gvm config" \
        "$gvm_config"
}

setup_oh_my_zsh() {
    if ! is_mac; then
        info "This is not mac, skipping Oh My Zsh installation"
        return 0
    fi

    info "🚀 Installing Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        success "Oh My Zsh installed"
    else
        debug "Oh My Zsh already installed"
    fi
}

setup_git_config() {
    info "🔧 Configuring Git..."

    git config --global alias.st "status --short"
    git config --global alias.c "commit"
    git config --global alias.co "checkout"
    git config --global alias.lg "log --all --decorate --graph --oneline"
    git config --global diff.algorithm histogram
    git config --global core.quotePath false
}

setup_tmux_plugin_manger() {
    info "🖥️ Setting up Tmux Plugin Manager..."

    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$tpm_dir" ]; then
        if clone_repo "https://github.com/tmux-plugins/tpm" "$tpm_dir"; then
            "$tpm_dir/bin/install_plugins"
            success "TPM installed"
        fi
    else
        debug "TPM already installed"
    fi
}

setup_pass() {
    info "💻🔐 pass password-store..."

    clone_repo "git@github.com:IlyasYOY/password-store.git" "$HOME/.password-store/" || true
}

setup_opencode() {
    info "🤖 Setting up OpenCode..."

    local opencode_config_dir="$HOME/.config/opencode"
    mkdir -pv "$opencode_config_dir"

    symlink \
        "$DOTFILES_DIR/config/opencode/AGENTS.md" \
        "$opencode_config_dir/AGENTS.md"
    configure_opencode_json \
        "$DOTFILES_DIR/config/opencode/opencode.json" \
        "$opencode_config_dir/opencode.json"
    symlink "$DOTFILES_DIR/config/opencode/commands" "$opencode_config_dir/commands"

    info "🤖 Setting up OpenCode skills..."
    local opencode_skills_dir="$opencode_config_dir/skills"
    mkdir -pv "$opencode_skills_dir"

    local skill
    for skill in caveman caveman-ru git-commit git-commit-split hammerspoon; do
        replace_managed_symlink \
            "$DOTFILES_DIR/config/opencode/skills/$skill" \
            "$opencode_skills_dir/$skill" \
            "$DOTFILES_DIR/config" \
            "/skills/$skill"
    done
}

main() {
    setup_basic_directories
    setup_platform_dependencies
    setup_notes
    setup_links_to_config_files
    setup_shell_rc
    setup_git_config
    setup_sdkman
    setup_go_version_manager
    setup_node_version_manager
    setup_oh_my_zsh
    setup_tmux_plugin_manger
    setup_my_project
    setup_pass

    setup_opencode

    success "🎉 Setup completed successfully!"
    info "Some changes might require a new shell session or system restart"
}

main "$@"

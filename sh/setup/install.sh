#!/usr/bin/env bash

source $(dirname $0)/helpers.sh
source $(dirname $0)/mac.sh

setup_basic_directories() {
    info "📁 Creating basic directories..."
    mkdir -pv "$PERSONAL_PROJECTS_DIR" "$WORK_PROJECTS_DIR"
}

setup_my_project() {
    info "👨💻 Setting up personal projects..."

    clone_repo "git@github.com:IlyasYOY/obs.nvim.git" "$PERSONAL_PROJECTS_DIR/obs.nvim"
    clone_repo "git@github.com:IlyasYOY/coredor.nvim.git" "$PERSONAL_PROJECTS_DIR/coredor.nvim"
    clone_repo "git@github.com:IlyasYOY/git-link.nvim.git" "$PERSONAL_PROJECTS_DIR/git-link.nvim"
    clone_repo "git@github.com:IlyasYOY/theme.nvim.git" "$PERSONAL_PROJECTS_DIR/theme.nvim"
    clone_repo "git@github.com:IlyasYOY/monotask.git" "$PERSONAL_PROJECTS_DIR/monotask"
    clone_repo "git@github.com:IlyasYOY/exectest.git" "$PERSONAL_PROJECTS_DIR/monotask"
}

setup_notes() {
    info "📝 Setting up notes..."

    clone_repo "git@github.com:IlyasYOY/notes-wiki.git" "$NOTES_DIR"
    clone_repo "git@github.com:IlyasYOY/Legacy-Notes.git" "$LEGACY_NOTES_DIR"
}

setup_links_to_config_files() {
    info "⚙️ Setting up config links..."
    local config_dir="$HOME/.config"
    mkdir -pv "$config_dir"

    # Main config links
    symlink "$DOTFILES_DIR/config/nvim" "$config_dir/nvim"
    symlink "$DOTFILES_DIR/config/nvim-minimal" "$config_dir/nvim-minimal"
    symlink "$DOTFILES_DIR/config/wezterm" "$config_dir/wezterm"
    symlink "$DOTFILES_DIR/config/hammerspoon" "$HOME/.hammerspoon"
    symlink "$DOTFILES_DIR/config/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
    gpgconf --kill gpg-agent && gpgconf --launch gpg-agent && debug "restart gpg-agent"


    # Git config
    mkdir -pv "$config_dir/git"
    symlink "$DOTFILES_DIR/config/.gitignore-global" "$config_dir/git/ignore"

    # Home directory links
    symlink "$DOTFILES_DIR/config/.golangci.yml" "$HOME_DIR/.golangci.yml"
    symlink "$DOTFILES_DIR/config/.tmux.conf" "$HOME_DIR/.tmux.conf"
    symlink "$DOTFILES_DIR/config/.vimrc" "$HOME_DIR/.vimrc"
    symlink "$DOTFILES_DIR/config/.amethyst.yml" "$HOME_DIR/.amethyst.yml"
}



setup_zshrc() {
    info "🐚 Configuring .zshrc..."

    local lines=(
        "export ILYASYOY_DOTFILES_DIR=\"$DOTFILES_DIR\""
        'source <(fzf --zsh)'
        "source \$ILYASYOY_DOTFILES_DIR/sh/helpers.sh"
        "source \$ILYASYOY_DOTFILES_DIR/sh/exports.sh"
        "source \$ILYASYOY_DOTFILES_DIR/sh/aliases.sh"
    )
    for line in "${lines[@]}"; do
        add_line "$line" "$ZSHRC"
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
}

setup_node_version_manager() {
    info "⬢ Installing fnm (Fast Node Manager)..."

    brew_install fnm

    # fnm configuration
    local fnm_config='eval "$(fnm env --use-on-cd --shell zsh)"'

    add_block "$ZSHRC" \
        "ilyasyoy fnm config" \
        "$fnm_config"
}

setup_go_version_manager() {
    info "🐹 Installing GVM..."
    if [ ! -d "$HOME/.gvm" ]; then
        bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
        # Source GVM immediately
        [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

        success "GVM installed"
    else 
        debug "GVM already installed"
    fi

    # GVM configuration
    local gvm_config=$'_gvm_lazy_load() {\n    unset -f gvm\n    [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"\n    "$@"\n}\ngvm() { _gvm_lazy_load gvm "$@" }'

    add_block "$ZSHRC" \
        "ilyasyoy gvm config" \
        "$gvm_config"
}

setup_oh_my_zsh() {
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
        clone_repo "https://github.com/tmux-plugins/tpm" "$tpm_dir"
        "$tpm_dir/bin/install_plugins"
        success "TPM installed"
    else
        debug "TPM already installed"
    fi
}

setup_pass() {
    info "💻🔐 pass password-store..."

    clone_repo "git@github.com:IlyasYOY/password-store.git" "$HOME/.password-store/"
}

setup_copilot() {
    info "🤖 Setting up Copilot..."

    local copilot_config_dir="$HOME/.copilot"
    if [ ! -d "$copilot_config_dir" ]; then
        warn "⚠️ Copilot config directory is absent. Please ensure Copilot is installed before proceeding."
        return
    fi

    info "🤖 Setting up Copilot instructions..."
    symlink "$DOTFILES_DIR/config/copilot/copilot-instructions.md" "$copilot_config_dir/copilot-instructions.md"


    info "🤖 Setting up Copilot agents..."
    symlink "$DOTFILES_DIR/config/copilot/agents" "$copilot_config_dir/agents"
}

main() {
    setup_basic_directories
    setup_notes
    setup_links_to_config_files
    setup_zshrc
    setup_git_config
    setup_sdkman
    setup_go_version_manager
    setup_node_version_manager
    setup_oh_my_zsh
    setup_tmux_plugin_manger
    setup_my_project
    setup_pass

    setup_copilot

    setup_mac_using_brew
    setup_mac_using_brew_cask
    setup_mac_using_app_store

    success "🎉 Setup completed successfully!"
    info "Some changes might require a new shell session or system restart"
}

main "$@"

#!/usr/bin/env bash


source ./helpers.sh

setup_mac_using_app_store() {
    info "🍎 Installing App Store packages..."

    if confirm_update "Update App Store packages"; then
        nvim --headless "+Lazy! sync" +qa && success "Lazy.nvim updated" || error "Failed to update Lazy.nvim"

        local apps=(
            937984704
            424390742
            1571033540
            1445910651
            424389933
            682658836
            1444383602
            408981434
            1208561404
            1035137927
            409183694
            302584613
            634148309
            441258766
            434290957
            409203825
            409201541
            904280696
            966085870
            1289119450
            1480933944
            310633997
        )

        for app in "${apps[@]}"; do
            mas_install "$app"
        done
    fi
}

setup_mac_using_brew() {
    info "🍺 Installing Homebrew packages..."
    local packages=(
        ast-grep
        bat
        bison
        cmake
        colima
        curl
        docker
        docker-compose
        fd
        ffmpeg
        fswatch
        fzf
        gh
        go
        mas
        neovim
        ollama
        openjdk
        pmd
        pre-commit
        pyenv
        python
        ripgrep
        rust
        scc
        sqlite
        syncthing
        tmux
        tree
        vim
        wget
    )
    for pkg in "${packages[@]}"; do
        brew_install "$pkg"
    done
}

setup_mac_using_brew_cask() {
    info "🍺 Installing Homebrew casks..."
    local casks=(
        alacritty
        amethyst
        betterdisplay
        discord
        google-chrome
        hammerspoon
        iina 
        karabiner-elements
        libreoffice
        netnewswire
        obsidian
        syncthing
        telegram
        vial
        wezterm
    )
    for cask in "${casks[@]}"; do
        brew_cask_install "$cask"
    done
}
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
}

setup_notes() {
    info "📝 Setting up notes..."
    clone_repo "git@github.com:IlyasYOY/Notes.git" "$NOTES_DIR"
    symlink "$NOTES_DIR" "$HOME_DIR/vimwiki"
}

setup_links_to_config_files() {
    info "⚙️ Setting up config links..."
    local config_dir="$HOME/.config"
    mkdir -pv "$config_dir"

    # Main config links
    symlink "$DOTFILES_DIR/config/nvim" "$config_dir/nvim"
    symlink "$DOTFILES_DIR/config/nvim-minimal" "$config_dir/nvim-minimal"
    symlink "$DOTFILES_DIR/config/alacritty" "$config_dir/alacritty"
    symlink "$DOTFILES_DIR/config/wezterm" "$config_dir/wezterm"
    symlink "$DOTFILES_DIR/config/hammerspoon" "$HOME/.hammerspoon"

    # Git config
    mkdir -pv "$config_dir/git"
    symlink "$DOTFILES_DIR/.gitignore-global" "$config_dir/git/ignore"

    # Home directory links
    symlink "$DOTFILES_DIR/config/.golangci.yml" "$HOME_DIR/.golangci.yml"
    symlink "$DOTFILES_DIR/.tmux.conf" "$HOME_DIR/.tmux.conf"
    symlink "$DOTFILES_DIR/.vimrc" "$HOME_DIR/.vimrc"
    symlink "$DOTFILES_DIR/.amethyst.yml" "$HOME_DIR/.amethyst.yml"
}



setup_zshrc() {
    info "🐚 Configuring .zshrc..."

    local lines=(
        'source <(fzf --zsh)'
    )
    for line in "${lines[@]}"; do
        add_line "$line" "$ZSHRC"
    done

    local aliases=$(cat <<-END
alias vimconfig="vim ~/.vimrc"
alias nvimconfig="nvim ~/.config/nvim/init.lua"
alias mnvim="NVIM_APPNAME=nvim-minimal nvim"
alias nvims="nvim -S"

alias cdfzf='cd "\$(find . -type d | fzf )"'
alias cdfzfgit='cd "\$(find . -name .git -type d -prune | fzf)/.."'

alias ilyasyoy-dotfiles="cd \${ILYASYOY_DOTFILES_DIR}"
alias ilyasyoy-notes="cd ~/vimwiki"
END
)
    add_block "$ZSHRC" \
        "aliases" \
        "$aliases"


    local exports=$(cat <<-END
export EDITOR=nvim
export TERM="xterm-256color"
export HISTCONTROL=ignoreboth:erasedups

export PATH="\$HOME/go/bin:\$PATH"
export PATH="\$HOME/local/bin:\$PATH"

export ILYASYOY_DOTFILES_DIR="\$DOTFILES_DIR"
export COLIMA_HOME=\$HOME/.colima
export DOCKER_HOST="unix://\${COLIMA_HOME}/default/docker.sock"
export PATH="\${ILYASYOY_DOTFILES_DIR}/bin:\$PATH"
END
)
    add_block "$ZSHRC" \
        "exports" \
        "$exports"
        
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
    info "⬢ Installing Node Version Manager..."
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

        # Source and install Node.js
        export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts

        success "NVM installed"
    else 
        debug "NVM already installed"
    fi

    # NVM configuration
    local nvm_config=$'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'

    add_block "$ZSHRC" \
        "nvm config" \
        "$nvm_config"
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
    local gvm_config=$'[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"'
    
    add_block "$ZSHRC" \
        "gvm config" \
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

main() {
    setup_mac_using_brew
    setup_mac_using_brew_cask
    setup_mac_using_app_store
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
    
    success "🎉 Setup completed successfully!"
    info "Some changes might require a new shell session or system restart"
}

main "$@"

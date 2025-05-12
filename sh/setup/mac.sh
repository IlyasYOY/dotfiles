#!/usr/bin/env bash

setup_mac_using_app_store() {
    if ! is_mac; then 
        info "This is not mac, skipping installing App Store applications"
        return 1;
    fi

    info "🍎 Installing App Store applications..."

    if confirm_update "Install App Store applications"; then
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
    if ! is_mac; then 
        info "This is not mac, skipping installing Homebrew packages"
        return 1;
    fi

    info "🍺 Installing Homebrew packages..."
    local packages=(
        aider
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
        tmuxp
        tree
        vim
        wget
    )
    for pkg in "${packages[@]}"; do
        brew_install "$pkg"
    done
}

setup_mac_using_brew_cask() {
    if ! is_mac; then 
        info "This is not mac, skipping installing Homebrew casks packages"
        return 1;
    fi

    info "🍺 Installing Homebrew casks packages..."
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


update_brew() {
    if ! is_mac; then 
        info "This is not mac, skipping updating Homebrew"
        return 1;
    fi

    info "🍺 Updating Homebrew..."

    brew update && success "Brew updated" || error "Failed to update Brew"
}

update_brew_packages() {
    if ! is_mac; then 
        info "This is not mac, skipping updating Homebrew packages"
        return 1;
    fi

    info "🍺 Updating Homebrew packages..."

    brew upgrade && success "Brew packages upgraded" || error "Failed to upgrade packages"
}

update_brew_cask_packages() {
    if ! is_mac; then 
        info "This is not mac, skipping updating Homebrew cask packages"
        return 1;
    fi

    info "🍺 Updating Homebrew cask packages..."

    brew upgrade --cask && success "Brew casks upgraded" || error "Failed to upgrade casks"
}

update_mas_applications() {
    if ! is_mac; then 
        info "This is not mac, skipping updating App Store applications"
        return 1;
    fi

    info "🍎 Updating App Store applications..."

    mas upgrade && success "Mas updated" || error "Failed to update mas"
}


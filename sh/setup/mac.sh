#!/usr/bin/env bash

setup_mac_using_app_store() {
    if ! is_mac; then 
        info "This is not mac, skipping installing App Store applications"
        return 1;
    fi

    info "🍎 Installing App Store applications..."

    if confirm_update "Install App Store applications"; then
        local apps=(
            1035137927
            1208561404
            1289119450
            1444383602
            1445910651
            1480933944
            1571033540
            302584613
            310633997
            408981434
            409183694
            409201541
            409203825
            424389933
            424390742
            434290957
            441258766
            634148309
            6446814690
            682658836
            904280696
            937984704
            966085870
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
        fzf
        gh
        go
        mas
        luacheck
        neovim
        ollama
        openai-whisper
        openjdk
        pass
        pinentry-mac
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
        typst
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

        font-fontawesome
        font-go-mono-nerd-font
        font-roboto
        font-roboto-mono-nerd-font
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

    if brew update; then
        success "Brew updated"
    else
        error "Failed to update Brew"
    fi
}

update_brew_packages() {
    if ! is_mac; then 
        info "This is not mac, skipping updating Homebrew packages"
        return 1;
    fi

    info "🍺 Updating Homebrew packages..."

    if brew upgrade; then
        success "Brew packages upgraded"
    else
        error "Failed to upgrade packages"
    fi
}

update_brew_cask_packages() {
    if ! is_mac; then 
        info "This is not mac, skipping updating Homebrew cask packages"
        return 1;
    fi

    info "🍺 Updating Homebrew cask packages..."

    if brew upgrade --cask; then
        success "Brew casks upgraded"
    else
        error "Failed to upgrade casks"
    fi
}

update_mas_applications() {
    if ! is_mac; then 
        info "This is not mac, skipping updating App Store applications"
        return 1;
    fi

    info "🍎 Updating App Store applications..."

    if mas upgrade; then
        success "Mas updated"
    else
        error "Failed to update mas"
    fi
}

#!/usr/bin/env bash

setup_mac_using_app_store() {
    if ! is_mac; then 
        info "This is not mac, skipping installing App Store applications"
        return 1;
    fi

    info "🍎 Installing App Store applications..."

    if confirm_update "Install App Store applications"; then
        brew_bundle_install "$DOTFILES_DIR/Brewfile.mac.mas" "App Store applications"
    fi
}

setup_mac_using_brew() {
    if ! is_mac; then 
        info "This is not mac, skipping installing Homebrew packages"
        return 1;
    fi

    info "🍺 Installing Homebrew packages..."
    brew_bundle_install "$DOTFILES_DIR/Brewfile.mac" "Homebrew packages"
}

setup_mac_using_brew_cask() {
    if ! is_mac; then 
        info "This is not mac, skipping installing Homebrew casks packages"
        return 1;
    fi

    info "🍺 Installing Homebrew casks packages..."
    brew_bundle_install "$DOTFILES_DIR/Brewfile.mac.cask" "Homebrew casks"
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

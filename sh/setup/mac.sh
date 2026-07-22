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

write_mac_default() {
    local domain="$1"
    local key="$2"
    shift 2

    if defaults write "$domain" "$key" "$@"; then
        return 0
    fi

    warning "Failed to write macOS default: $domain $key"
    return 1
}

setup_mac_pinentry_defaults() {
    if ! is_mac; then
        return 0
    fi

    info "🔐 Configuring pinentry defaults..."

    if write_mac_default org.gpgtools.common DisableKeychain -bool yes; then
        success "Pinentry defaults configured"
    else
        warning "Some pinentry defaults could not be applied"
    fi
}

setup_mac_defaults() {
    if ! is_mac; then
        info "This is not mac, skipping macOS defaults"
        return 0
    fi

    info "⚙️ Applying macOS defaults..."

    local mac_defaults_failed=0
    local current_reduce_transparency

    write_mac_default NSGlobalDomain AppleLanguages -array "en-RU" "ru-RU" || mac_defaults_failed=1
    write_mac_default NSGlobalDomain AppleLocale -string "en_RU" || mac_defaults_failed=1
    write_mac_default NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool true || mac_defaults_failed=1
    write_mac_default NSGlobalDomain AppleShowAllExtensions -bool true || mac_defaults_failed=1
    write_mac_default NSGlobalDomain ApplePressAndHoldEnabled -bool false || mac_defaults_failed=1

    write_mac_default com.apple.finder ShowStatusBar -bool true || mac_defaults_failed=1
    write_mac_default com.apple.finder FXPreferredViewStyle -string "clmv" || mac_defaults_failed=1
    write_mac_default com.apple.finder ShowExternalHardDrivesOnDesktop -bool true || mac_defaults_failed=1
    write_mac_default com.apple.finder ShowHardDrivesOnDesktop -bool true || mac_defaults_failed=1
    write_mac_default com.apple.finder ShowMountedServersOnDesktop -bool true || mac_defaults_failed=1
    write_mac_default com.apple.finder ShowRemovableMediaOnDesktop -bool true || mac_defaults_failed=1

    write_mac_default com.apple.dock autohide -bool true || mac_defaults_failed=1
    write_mac_default com.apple.dock tilesize -int 64 || mac_defaults_failed=1

    write_mac_default com.apple.menuextra.clock IsAnalog -bool true || mac_defaults_failed=1
    write_mac_default com.apple.menuextra.clock ShowDate -int 2 || mac_defaults_failed=1
    write_mac_default com.apple.menuextra.clock ShowDayOfWeek -bool false || mac_defaults_failed=1
    write_mac_default com.apple.menuextra.clock TimeAnnouncementsEnabled -bool false || mac_defaults_failed=1

    if current_reduce_transparency=$(defaults read com.apple.universalaccess reduceTransparency 2>/dev/null) &&
        [ "$current_reduce_transparency" = "1" ]; then
        debug "macOS default already set: com.apple.universalaccess reduceTransparency"
    else
        write_mac_default com.apple.universalaccess reduceTransparency -bool true || mac_defaults_failed=1
    fi

    if [ "$mac_defaults_failed" -eq 0 ]; then
        success "macOS defaults applied"
    else
        warning "Some macOS defaults could not be applied"
    fi

    return 0
}

restart_mac_ui_services() {
    if ! is_mac; then
        info "This is not mac, skipping macOS UI restart"
        return 0
    fi

    info "🔄 Restarting macOS UI services..."

    local service
    for service in Dock Finder SystemUIServer; do
        killall "$service" >/dev/null 2>&1 || true
    done

    success "macOS UI services restarted"
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

    if brew upgrade -y; then
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

    if brew upgrade --cask -y; then
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

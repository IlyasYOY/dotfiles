#!/usr/bin/env bash

apt_install() {
    local dependency="$1"

    if dpkg -s "$dependency" >/dev/null 2>&1; then
        debug "apt $dependency already installed"
        return 0
    fi

    if sudo apt-get install -y "$dependency"; then
        success "apt installed $dependency"
    else
        error "apt failed to install $dependency"
        return 1
    fi
}

load_linux_brew() {
    load_brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"
}

setup_raspberry_pi_system_update() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping apt update and upgrade"
        return 1
    fi

    info "🍓 Updating apt package lists..."

    if sudo apt-get update && sudo apt-get upgrade -y; then
        success "apt updated and upgraded"
    else
        error "Failed to update and upgrade apt packages"
        return 1
    fi
}

setup_raspberry_pi_brew_prerequisites() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping Homebrew prerequisites"
        return 1
    fi

    info "🍓 Installing Raspberry Pi bootstrap prerequisites..."

    local packages=(
        bison
        build-essential
        ca-certificates
        curl
        file
        git
        gnupg
        pinentry-curses
        procps
    )

    local pkg
    for pkg in "${packages[@]}"; do
        apt_install "$pkg" || return 1
    done
}

setup_raspberry_pi_sing_box() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping sing-box installation"
        return 1
    fi

    info "🍓 Installing sing-box..."

    sudo mkdir -p /etc/apt/keyrings || return 1
    if [ ! -f /etc/apt/keyrings/sagernet.asc ]; then
        sudo curl -fsSL https://sing-box.app/gpg.key -o /etc/apt/keyrings/sagernet.asc || return 1
        sudo chmod a+r /etc/apt/keyrings/sagernet.asc || return 1
    else
        debug "sing-box apt key already exists"
    fi

    local sagernet_repo
    sagernet_repo=$'Types: deb\nURIs: https://deb.sagernet.org/\nSuites: *\nComponents: *\nEnabled: yes\nSigned-By: /etc/apt/keyrings/sagernet.asc\n'

    if ! sudo test -f /etc/apt/sources.list.d/sagernet.sources; then
        printf "%s" "$sagernet_repo" | sudo tee /etc/apt/sources.list.d/sagernet.sources >/dev/null || return 1
        success "Configured sing-box apt repository"
    else
        debug "sing-box apt repository already configured"
    fi

    sudo apt-get update || return 1
    apt_install sing-box
}

setup_raspberry_pi_homebrew() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping Homebrew installation"
        return 1
    fi

    info "🍓 Installing Homebrew..."

    if ! load_linux_brew; then
        NONINTERACTIVE=1 run_downloaded_installer \
            https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh /bin/bash || return 1
        if ! load_linux_brew; then
            error "Homebrew installed but could not be loaded into the current shell"
            return 1
        fi
        success "Homebrew installed"
    else
        debug "Homebrew already installed"
    fi

    persist_brew_shellenv "ilyasyoy linuxbrew config"
}

setup_raspberry_pi_homebrew_dependencies() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping Raspberry Pi Homebrew dependencies"
        return 1
    fi

    info "🍓 Installing Raspberry Pi Homebrew dependencies..."

    if ! load_linux_brew; then
        error "Homebrew is required before installing Raspberry Pi Homebrew dependencies"
        return 1
    fi

    brew_bundle_install "$DOTFILES_DIR/Brewfile.raspberry-pi" "Raspberry Pi Homebrew dependencies"
}

setup_raspberry_pi() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping Raspberry Pi bootstrap"
        return 1
    fi

    setup_raspberry_pi_system_update || return 1
    setup_raspberry_pi_brew_prerequisites || return 1
    setup_raspberry_pi_sing_box || return 1
    setup_raspberry_pi_homebrew || return 1
    setup_raspberry_pi_homebrew_dependencies
}

update_raspberry_pi_system() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping apt update and upgrade"
        return 1
    fi

    info "🍓 Updating apt package lists..."

    if sudo apt-get update && sudo apt-get upgrade -y; then
        success "apt updated and upgraded"
    else
        error "Failed to update and upgrade apt packages"
        return 1
    fi
}

update_raspberry_pi_brew() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping Homebrew update"
        return 1
    fi

    if ! load_linux_brew; then
        error "Homebrew is not available"
        return 1
    fi

    info "🍓 Updating Homebrew..."

    if brew update; then
        success "Homebrew updated"
    else
        error "Failed to update Homebrew"
        return 1
    fi
}

update_raspberry_pi_brew_packages() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping Homebrew packages upgrade"
        return 1
    fi

    if ! load_linux_brew; then
        error "Homebrew is not available"
        return 1
    fi

    info "🍓 Upgrading Homebrew packages..."

    if brew upgrade; then
        success "Homebrew packages upgraded"
    else
        error "Failed to upgrade Homebrew packages"
        return 1
    fi
}

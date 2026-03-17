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
    fi
}

load_linux_brew() {
    if command -v brew >/dev/null 2>&1; then
        return 0
    fi

    if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        return 0
    fi

    if [ -x "$HOME/.linuxbrew/bin/brew" ]; then
        eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
        return 0
    fi

    return 1
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
        procps
    )

    local pkg
    for pkg in "${packages[@]}"; do
        apt_install "$pkg"
    done
}

setup_raspberry_pi_sing_box() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping sing-box installation"
        return 1
    fi

    info "🍓 Installing sing-box..."

    sudo mkdir -p /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/sagernet.asc ]; then
        sudo curl -fsSL https://sing-box.app/gpg.key -o /etc/apt/keyrings/sagernet.asc
        sudo chmod a+r /etc/apt/keyrings/sagernet.asc
    else
        debug "sing-box apt key already exists"
    fi

    local sagernet_repo
    sagernet_repo=$'Types: deb\nURIs: https://deb.sagernet.org/\nSuites: *\nComponents: *\nEnabled: yes\nSigned-By: /etc/apt/keyrings/sagernet.asc\n'

    if ! sudo test -f /etc/apt/sources.list.d/sagernet.sources; then
        printf "%s" "$sagernet_repo" | sudo tee /etc/apt/sources.list.d/sagernet.sources >/dev/null
        success "Configured sing-box apt repository"
    else
        debug "sing-box apt repository already configured"
    fi

    sudo apt-get update
    apt_install sing-box
}

setup_raspberry_pi_homebrew() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping Homebrew installation"
        return 1
    fi

    info "🍓 Installing Homebrew..."

    if ! load_linux_brew; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if ! load_linux_brew; then
            error "Homebrew installed but could not be loaded into the current shell"
        fi
        success "Homebrew installed"
    else
        debug "Homebrew already installed"
    fi

    local brew_config
    brew_config=$'test -d ~/.linuxbrew && eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"\ntest -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    add_block "$(shell_rc_file)" "ilyasyoy linuxbrew config" "$brew_config"
}

setup_raspberry_pi_requested_tools() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping Raspberry Pi requested tools"
        return 1
    fi

    info "🍓 Installing Raspberry Pi requested tools..."

    if ! load_linux_brew; then
        error "Homebrew is required before installing Raspberry Pi requested tools"
    fi

    brew_install gh
}

setup_raspberry_pi_core_dependencies() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping Raspberry Pi core dependencies"
        return 1
    fi

    info "🍓 Installing Raspberry Pi core dependencies with Homebrew..."

    if ! load_linux_brew; then
        error "Homebrew is required before installing Raspberry Pi core dependencies"
    fi

    brew_install fzf
    brew_install neovim
    brew_install python
    brew_install ripgrep
    brew_install rust
    brew_install luacheck
    brew_install tree-sitter-cli
    brew_install tmux
    brew_install wget
    brew_install go
    brew_install pass
}

setup_raspberry_pi() {
    if ! is_raspberry_pi; then
        info "This is not Raspberry Pi, skipping Raspberry Pi bootstrap"
        return 1
    fi

    setup_raspberry_pi_system_update
    setup_raspberry_pi_brew_prerequisites
    setup_raspberry_pi_sing_box
    setup_raspberry_pi_homebrew
    setup_raspberry_pi_requested_tools
    setup_raspberry_pi_core_dependencies
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
    fi
}

#!/usr/bin/env bash

set -euo pipefail

# Configuration variables
HOME_DIR="$HOME"
PROJECTS_DIR="$HOME/Projects"
WORK_PROJECTS_DIR="$PROJECTS_DIR/Work"
PERSONAL_PROJECTS_DIR="$PROJECTS_DIR/IlyasYOY"
NOTES_DIR="$PERSONAL_PROJECTS_DIR/Notes"
ZSHRC="$HOME/.zshrc"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() {
    printf "\n\033[1;34m%s\033[0m\n" "$1"
}

success() {
    printf "\n✅ \033[1;32m%s\033[0m" "$1"
}

debug() {
    printf "\n\033[1;37m%s\033[0m" "$1"
}

error() {
    printf "\n💥 \033[1;31m%s\033[0m" "$1"
}

warning() {
    printf "\n⚠️ \033[1;33m%s\033[0m" "$1"
}

confirm_update() {
    local message=$1

    read -p "$message [y/n]: " answer

    if [[ $answer == "y" || $answer == "Y" ]]; then
        return 0  # Success, proceed with update
    else
        info "Skipping $message."
        return 1  # Skip update
    fi
}

add_line() {
    local line="$1"
    local dest="$2"

    if ! grep -qxF "$line" "$ZSHRC"; then
        echo "$line" >> "$ZSHRC"
        success "Line '$line' in file $dest"
    else
        debug "Line '$line' already exists in file $dest"
    fi
}

add_block() {
    local file="$1"
    local start_marker="$2"
    local end_marker="$3"
    local content="$4"

    # Check if the block already exists
    if ! grep -qF "$start_marker" "$file"; then
        printf "\n%s\n" "$start_marker" >> "$file"
        printf "%b\n" "$content" >> "$file"
        printf "%s\n" "$end_marker" >> "$file"
        success "Added configuration block to $file"
    else
        debug "Configuration block already exists in $file"
    fi
}

symlink() {
    local target="$1"
    local link="$2"

    if [ ! -e "$link" ]; then
        ln -sv "$target" "$link"
        success "Added symlink $link to $target"
    elif [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
        debug "Symlink already exists: $link"
    else
        warning "$link exists but is not a symlink to $target"
    fi
}

clone_repo() {
    local repo="$1"
    local dest="$2"
    
    if [ ! -d "$dest" ]; then
        git clone "$repo" "$dest"
        success "Repository cloned $repo to $dest"
    else
        debug "☑️Repository already exists: $dest"
    fi
}

brew_install() {
    local dependency="$1"

    if ! brew ls --versions "$dependency" >/dev/null; then
        brew install "$dependency"
        success "brew installed $dependency"
    else
        debug "brew $dependency already installed"
    fi
}

brew_cask_install() {
    if ! brew list --cask "$1" >/dev/null 2>&1; then
        brew install --cask "$1"
        success "brew cask installed $dependency"
    else
        debug "brew cask $1 already installed"
    fi
}


#!/usr/bin/env bash

set -euo pipefail

# Configuration variables
HOME_DIR="$HOME"
PROJECTS_DIR="$HOME/Projects"
WORK_PROJECTS_DIR="$PROJECTS_DIR/Work"
PERSONAL_PROJECTS_DIR="$PROJECTS_DIR/IlyasYOY"
NOTES_DIR="$PERSONAL_PROJECTS_DIR/notes-wiki"
LEGACY_NOTES_DIR="$PERSONAL_PROJECTS_DIR/Legacy-Notes"
ZSHRC="$HOME/.zshrc"
DOTFILES_DIR=$(realpath $(dirname $0)/../../)

is_mac() {
    [[ "$(uname -s)" == "Darwin" ]]
}

info() {
    printf "\n\033[1;34m%s\033[0m\n" "$1"
}

success() {
    printf "✅ \033[1;32m%s\033[0m\n" "$1"
}

debug() {
    printf "\033[1;37m%s\033[0m\n" "$1"
}

debug "dotfile root path: $DOTFILES_DIR"

error() {
    printf "💥 \033[1;31m%s\033[0m\n" "$1"
}

warning() {
    printf "⚠️ \033[1;33m%s\033[0m\n" "$1"
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
    local marker="$2"
    local content="$3"

    # Check if the block already exists
    if ! grep -qF "$marker" "$file"; then
        printf "## start %s ##\n" "$marker" >> "$file"
        printf "%b\n" "$content" >> "$file"
        printf "## end %s ##\n" "$marker" >> "$file"

        success "Added configuration block $marker to $file"
    else
        debug "Configuration block $marker already exists in $file"
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
        git clone "$repo" "$dest" \
            && success "Repository cloned $repo to $dest" \
            || error "Repository $repo cannot be cloned to $dest"
    else
        debug "Repository already exists: $dest"
    fi
}


mas_install() {
    local dependency_id="$1"

    if ! mas info "$dependency_id" >/dev/null; then
        mas install "$dependency_id" \
             && success "mas installed $dependency_id" \
             || error "mas failed to install $dependency_id"
    else
        debug "mas $dependency_id already installed"
    fi
}

brew_install() {
    local dependency="$1"

    if ! brew ls --versions "$dependency" >/dev/null; then
        brew install "$dependency" \
             && success "brew installed $dependency" \
             || error "brew failed to install $dependency"
    else
        debug "brew $dependency already installed"
    fi
}

brew_cask_install() {
    local dependency="$1"

    if ! brew list --cask "$dependency" >/dev/null 2>&1; then
        brew install --cask "$dependency" \
             && success "brew cask installed $dependency" \
             || error "brew cask failed to install $dependency"
    else
        debug "brew cask $dependency already installed"
    fi
}


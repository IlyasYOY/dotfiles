#!/usr/bin/env bash

set -euo pipefail

# Configuration variables shared by setup scripts that source this file.
export HOME_DIR="$HOME"
PROJECTS_DIR="$HOME/Projects"
export WORK_PROJECTS_DIR="$PROJECTS_DIR/Work"
PERSONAL_PROJECTS_DIR="$PROJECTS_DIR/IlyasYOY"
export NOTES_DIR="$PERSONAL_PROJECTS_DIR/notes-wiki"
export LEGACY_NOTES_DIR="$PERSONAL_PROJECTS_DIR/Legacy-Notes"
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"
DOTFILES_DIR=$(realpath "$(dirname "$0")"/../../)

is_mac() {
    [[ "$(uname -s)" == "Darwin" ]]
}

is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
}

is_raspberry_pi() {
    if ! is_linux; then
        return 1
    fi

    local model_file
    for model_file in /proc/device-tree/model /sys/firmware/devicetree/base/model; do
        if [ -r "$model_file" ] && tr -d '\0' < "$model_file" | grep -qi "Raspberry Pi"; then
            return 0
        fi
    done

    if [ -r /etc/os-release ] && grep -qiE "raspbian|Raspberry Pi OS" /etc/os-release; then
        return 0
    fi

    return 1
}

shell_rc_file() {
    if is_raspberry_pi; then
        printf "%s\n" "$BASHRC"
        return 0
    fi

    printf "%s\n" "$ZSHRC"
}

shell_name() {
    if is_raspberry_pi; then
        printf "bash\n"
        return 0
    fi

    printf "zsh\n"
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

warn() {
    warning "$1"
}

confirm_update() {
    local message=$1

    read -r -p "$message [y/n]: " answer

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

    if ! grep -qxF "$line" "$dest"; then
        echo "$line" >> "$dest"
        success "Line '$line' in file $dest"
    else
        debug "Line '$line' already exists in file $dest"
    fi
}

add_block() {
    local file="$1"
    local marker="$2"
    local content="$3"
    local start_marker end_marker
    start_marker="## start $marker ##"
    end_marker="## end $marker ##"

    if grep -qF "$start_marker" "$file"; then
        python3 - <<'PY' "$file" "$start_marker" "$end_marker" "$content"
from pathlib import Path
import sys

path = Path(sys.argv[1])
start_marker = sys.argv[2]
end_marker = sys.argv[3]
content = sys.argv[4]

lines = path.read_text().splitlines()
start = lines.index(start_marker)
end = lines.index(end_marker, start + 1)

replacement = [start_marker, *content.splitlines(), end_marker]
updated = lines[:start] + replacement + lines[end + 1 :]
path.write_text("\n".join(updated) + "\n")
PY
        success "Updated configuration block $marker in $file"
    else
        {
            printf "%s\n" "$start_marker"
            printf "%b\n" "$content"
            printf "%s\n" "$end_marker"
        } >> "$file"

        success "Added configuration block $marker to $file"
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
        if git clone "$repo" "$dest"; then
            success "Repository cloned $repo to $dest"
        else
            error "Repository $repo cannot be cloned to $dest"
        fi
    else
        debug "Repository already exists: $dest"
    fi
}


mas_install() {
    local dependency_id="$1"

    if ! mas info "$dependency_id" >/dev/null; then
        if mas install "$dependency_id"; then
            success "mas installed $dependency_id"
        else
            error "mas failed to install $dependency_id"
        fi
    else
        debug "mas $dependency_id already installed"
    fi
}

brew_install() {
    local dependency="$1"

    if ! brew ls --versions "$dependency" >/dev/null; then
        if brew install "$dependency"; then
            success "brew installed $dependency"
        else
            error "brew failed to install $dependency"
        fi
    else
        debug "brew $dependency already installed"
    fi
}

brew_cask_install() {
    local dependency="$1"

    if ! brew list --cask "$dependency" >/dev/null 2>&1; then
        if brew install --cask "$dependency"; then
            success "brew cask installed $dependency"
        else
            error "brew cask failed to install $dependency"
        fi
    else
        debug "brew cask $dependency already installed"
    fi
}

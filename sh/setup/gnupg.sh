#!/usr/bin/env bash

setup_gnupg() {
    local pinentry prefix
    if is_mac; then
        prefix=$(brew --prefix pinentry-touchid) || return 1
        pinentry="$prefix/bin/pinentry-touchid"
    elif is_raspberry_pi; then
        apt_install pinentry-curses || return 1
        pinentry=$(command -v pinentry-curses) || {
            error "pinentry-curses is not available"
            return 1
        }
    else
        return 0
    fi
    if [ ! -x "$pinentry" ]; then
        error "Pinentry executable is unavailable: $pinentry"
        return 1
    fi

    local link="$HOME/.gnupg/gpg-agent.conf"
    local generated="$HOME/.config/dotfiles/gpg-agent.conf"
    local legacy="$DOTFILES_DIR/config/gnupg/gpg-agent.conf"
    local marker='# Managed by dotfiles: gpg-agent'
    local target='' temporary backup
    if [ -L "$link" ]; then
        target=$(readlink "$link") || return 1
        if [ "$target" != "$generated" ] && [ "$target" != "$legacy" ]; then
            warning "$link points elsewhere; leaving it unchanged"
            return 0
        fi
    elif [ -e "$link" ]; then
        warning "$link is user-owned; leaving it unchanged"
        return 0
    fi
    if [ -L "$generated" ] || { [ -e "$generated" ] &&
        { [ ! -f "$generated" ] || [ "$(head -n 1 "$generated")" != "$marker" ]; }; }; then
        warning "$generated is user-owned; leaving it unchanged"
        return 0
    fi

    mkdir -p "$HOME/.gnupg" "$(dirname "$generated")" || return 1
    temporary=$(mktemp "${generated}.XXXXXX") || return 1
    if ! {
        printf '%s\n' "$marker"
        printf 'pinentry-program %s\n' "$pinentry"
        sed '/^[[:space:]]*pinentry-program[[:space:]]/d' "$legacy"
    } > "$temporary"; then
        rm -f "$temporary"
        return 1
    fi
    if ! mv "$temporary" "$generated"; then
        rm -f "$temporary"
        return 1
    fi
    if [ "$target" = "$legacy" ]; then
        backup=$(mktemp -d "$HOME/.gnupg/dotfiles-backup.XXXXXX") || return 1
        mv "$link" "$backup/gpg-agent.conf" || return 1
        info "Previous GnuPG configuration link saved to $backup/gpg-agent.conf"
    fi
    symlink "$generated" "$link" || return 1
    setup_mac_pinentry_defaults || return 1
    if command -v gpgconf >/dev/null 2>&1; then
        gpgconf --kill gpg-agent || return 1
        gpgconf --launch gpg-agent || return 1
    fi
}

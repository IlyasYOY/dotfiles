#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "$0")/helpers.sh"

ensure_workbench() {
    local name="$1"
    local destination="$2"

    if [ -f "$destination/Makefile" ]; then
        return 0
    fi
    if [ -e "$destination" ]; then
        error "$destination exists but is not an installed $name workbench"
        return 1
    fi

    clone_repo "git@github.com:IlyasYOY/$name.git" "$destination"
}

install_workbenches() {
    ensure_workbench "nvim-workbench" "$NVIM_WORKBENCH_DIR"
    ensure_workbench "agent-workbench" "$AGENT_WORKBENCH_DIR"

    make -C "$NVIM_WORKBENCH_DIR" install
    make -C "$AGENT_WORKBENCH_DIR" install
}

update_workbenches() {
    ensure_workbench "nvim-workbench" "$NVIM_WORKBENCH_DIR"
    ensure_workbench "agent-workbench" "$AGENT_WORKBENCH_DIR"

    make -C "$NVIM_WORKBENCH_DIR" update
    make -C "$AGENT_WORKBENCH_DIR" update
}

case "${1:-}" in
    install)
        install_workbenches
        ;;
    update)
        update_workbenches
        ;;
    *)
        error "Usage: $0 {install|update}"
        exit 2
        ;;
esac

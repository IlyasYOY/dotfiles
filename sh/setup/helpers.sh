#!/usr/bin/env bash

set -euo pipefail

# Configuration variables shared by setup scripts that source this file.
export HOME_DIR="$HOME"
PROJECTS_DIR="$HOME/Projects"
export WORK_PROJECTS_DIR="$PROJECTS_DIR/Work"
export PERSONAL_PROJECTS_DIR="$PROJECTS_DIR/IlyasYOY"
export KB_DIR="${ILYASYOY_KB_STORE_DIR:-$PROJECTS_DIR/kb-store}"
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

is_verbose() {
    case "${VERBOSE:-0}" in
        1|true|TRUE|True|yes|YES|Yes|y|Y)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

info() {
    printf "\n\033[1;34m%s\033[0m\n" "$1"
}

success() {
    printf "✅ \033[1;32m%s\033[0m\n" "$1"
}

debug() {
    if ! is_verbose; then
        return 0
    fi

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

add_toml_root_block() {
    local file="$1"
    local marker="$2"
    local content="$3"
    local start_marker end_marker content_file tmp_file
    start_marker="## start $marker ##"
    end_marker="## end $marker ##"

    mkdir -p "$(dirname "$file")"
    touch "$file"
    content_file=$(mktemp "${TMPDIR:-/tmp}/dotfiles-toml-root-content.XXXXXX")
    tmp_file=$(mktemp "${TMPDIR:-/tmp}/dotfiles-toml-root.XXXXXX")
    printf "%s\n" "$content" > "$content_file"

    awk \
        -v start_marker="$start_marker" \
        -v end_marker="$end_marker" \
        -v content_file="$content_file" \
        '
        BEGIN {
            while ((getline line < content_file) > 0) {
                content_count++
                content_lines[content_count] = line
            }
            close(content_file)

            for (idx = 1; idx <= content_count; idx++) {
                line = content_lines[idx]
                if (line ~ /^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*=/) {
                    key = line
                    sub(/^[[:space:]]*/, "", key)
                    sub(/[[:space:]]*=.*/, "", key)
                    managed_keys[key] = 1
                }
            }
        }

        function trim(value) {
            sub(/^[[:space:]]*/, "", value)
            sub(/[[:space:]]*$/, "", value)
            return value
        }

        function header_name(line) {
            sub(/[[:space:]]*#.*/, "", line)
            line = trim(line)

            if (line !~ /^\[[^][]+\]$/) {
                return ""
            }

            sub(/^\[/, "", line)
            sub(/\]$/, "", line)
            return line
        }

        function line_key(line) {
            if (line !~ /^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*=/) {
                return ""
            }

            sub(/^[[:space:]]*/, "", line)
            sub(/[[:space:]]*=.*/, "", line)
            return line
        }

        function print_block() {
            print start_marker

            for (idx = 1; idx <= content_count; idx++) {
                print content_lines[idx]
            }

            print end_marker
            block_written = 1
        }

        $0 == start_marker {
            skip_block = 1
            next
        }

        skip_block {
            if ($0 == end_marker) {
                skip_block = 0
            }

            next
        }

        {
            if (header_name($0) != "") {
                if (!block_written) {
                    if (printed_any && previous_line != "") {
                        print ""
                    }

                    print_block()
                }

                in_table = 1
                print
                printed_any = 1
                previous_line = $0
                next
            }

            if (!in_table && line_key($0) in managed_keys) {
                next
            }

            print
            printed_any = 1
            previous_line = $0
        }

        END {
            if (!block_written) {
                if (printed_any && previous_line != "") {
                    print ""
                }

                print_block()
            }
        }
        ' "$file" > "$tmp_file"

    if cmp -s "$file" "$tmp_file"; then
        rm -f "$content_file" "$tmp_file"
        debug "Configuration block $marker already exists in $file"
    else
        mv "$tmp_file" "$file"
        rm -f "$content_file"
        success "Configured TOML block $marker in $file"
    fi
}

add_toml_table_block() {
    local file="$1"
    local table="$2"
    local marker="$3"
    local content="$4"
    local start_marker end_marker content_file tmp_file
    start_marker="## start $marker ##"
    end_marker="## end $marker ##"

    mkdir -p "$(dirname "$file")"
    touch "$file"
    content_file=$(mktemp "${TMPDIR:-/tmp}/dotfiles-toml-block-content.XXXXXX")
    tmp_file=$(mktemp "${TMPDIR:-/tmp}/dotfiles-toml-block.XXXXXX")
    printf "%s\n" "$content" > "$content_file"

    awk \
        -v table="$table" \
        -v start_marker="$start_marker" \
        -v end_marker="$end_marker" \
        -v content_file="$content_file" \
        '
        BEGIN {
            while ((getline line < content_file) > 0) {
                content_count++
                content_lines[content_count] = line
            }
            close(content_file)

            for (idx = 1; idx <= content_count; idx++) {
                line = content_lines[idx]
                if (line ~ /^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*=/) {
                    key = line
                    sub(/^[[:space:]]*/, "", key)
                    sub(/[[:space:]]*=.*/, "", key)
                    managed_keys[key] = 1
                }
            }
        }

        function trim(value) {
            sub(/^[[:space:]]*/, "", value)
            sub(/[[:space:]]*$/, "", value)
            return value
        }

        function header_name(line) {
            sub(/[[:space:]]*#.*/, "", line)
            line = trim(line)

            if (line !~ /^\[[^][]+\]$/) {
                return ""
            }

            sub(/^\[/, "", line)
            sub(/\]$/, "", line)
            return line
        }

        function line_key(line) {
            if (line !~ /^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*=/) {
                return ""
            }

            sub(/^[[:space:]]*/, "", line)
            sub(/[[:space:]]*=.*/, "", line)
            return line
        }

        function print_block() {
            print start_marker

            for (idx = 1; idx <= content_count; idx++) {
                print content_lines[idx]
            }

            print end_marker
        }

        $0 == start_marker {
            skip_block = 1
            next
        }

        skip_block {
            if ($0 == end_marker) {
                skip_block = 0
            }

            next
        }

        {
            current_header = header_name($0)

            if (current_header != "") {
                in_target_table = current_header == table

                print

                if (in_target_table) {
                    target_seen = 1
                    block_written = 1
                    print_block()
                }

                next
            }

            if (in_target_table && line_key($0) in managed_keys) {
                next
            }

            print
        }

        END {
            if (!target_seen) {
                if (NR > 0) {
                    print ""
                }

                print "[" table "]"
                print_block()
            }
        }
        ' "$file" > "$tmp_file"

    if cmp -s "$file" "$tmp_file"; then
        rm -f "$content_file" "$tmp_file"
        debug "Configuration block $marker already exists in $file"
    else
        mv "$tmp_file" "$file"
        rm -f "$content_file"
        success "Configured TOML block $marker in $file"
    fi
}

configure_opencode_json() {
    local default_config="$1"
    local dest_config="$2"
    local dest_dir

    dest_dir=$(dirname "$dest_config")
    mkdir -p "$dest_dir"

    if [ ! -e "$dest_config" ] && [ ! -L "$dest_config" ]; then
        symlink "$default_config" "$dest_config"
        return 0
    fi

    if [ -L "$dest_config" ]; then
        if [ "$(readlink "$dest_config")" = "$default_config" ]; then
            debug "OpenCode config already links to $default_config"
        else
            warning "$dest_config is a symlink to another target; leaving it unchanged"
        fi
        return 0
    fi

    if [ ! -r "$dest_config" ]; then
        warning "$dest_config is not readable; leaving it unchanged"
        return 0
    fi

    python3 - <<'PY' "$default_config" "$dest_config"
from __future__ import annotations

import json
import shutil
import sys
import time
from pathlib import Path
from typing import Any


def deep_fill(existing: dict[str, Any], defaults: dict[str, Any]) -> bool:
    changed = False

    for key, default_value in defaults.items():
        if key not in existing:
            existing[key] = default_value
            changed = True
            continue

        existing_value = existing[key]
        if isinstance(existing_value, dict) and isinstance(default_value, dict):
            changed = deep_fill(existing_value, default_value) or changed

    return changed


def fill_skill_permission(config: dict[str, Any], defaults: dict[str, Any]) -> bool:
    default_permission = defaults.get("permission")
    if not isinstance(default_permission, dict):
        return False

    default_skill = default_permission.get("skill")
    if not isinstance(default_skill, dict):
        return False

    permission = config.get("permission")
    if not isinstance(permission, dict):
        return False

    existing_skill = permission.get("skill")
    if isinstance(existing_skill, dict):
        return deep_fill(existing_skill, default_skill)

    if isinstance(existing_skill, str):
        permission["skill"] = {"*": existing_skill}
        return deep_fill(permission["skill"], default_skill) or True

    if existing_skill is None:
        permission["skill"] = default_skill
        return True

    return False


default_path = Path(sys.argv[1])
dest_path = Path(sys.argv[2])

try:
    defaults = json.loads(default_path.read_text())
except OSError as exc:
    print(f"warning: cannot read {default_path}: {exc}", file=sys.stderr)
    sys.exit(0)
except json.JSONDecodeError as exc:
    print(f"warning: {default_path} is not strict JSON: {exc}", file=sys.stderr)
    sys.exit(0)

if not isinstance(defaults, dict):
    print(f"warning: {default_path} is not a JSON object", file=sys.stderr)
    sys.exit(0)

try:
    config = json.loads(dest_path.read_text())
except OSError as exc:
    print(f"warning: cannot read {dest_path}: {exc}", file=sys.stderr)
    sys.exit(0)
except json.JSONDecodeError as exc:
    print(f"warning: {dest_path} is not strict JSON: {exc}", file=sys.stderr)
    sys.exit(0)

if not isinstance(config, dict):
    print(f"warning: {dest_path} is not a JSON object; leaving it unchanged", file=sys.stderr)
    sys.exit(0)

changed = deep_fill(config, defaults)
changed = fill_skill_permission(config, defaults) or changed

if not changed:
    print(f"debug: {dest_path} already contains OpenCode defaults")
    sys.exit(0)

timestamp = time.strftime("%Y%m%d%H%M%S")
backup_path = dest_path.with_name(f"{dest_path.name}.{timestamp}.bak")
shutil.copy2(dest_path, backup_path)
dest_path.write_text(json.dumps(config, indent=2) + "\n")
print(f"updated: {dest_path} (backup: {backup_path})")
PY
}

symlink() {
    local target="$1"
    local link="$2"

    if [ -L "$link" ]; then
        if [ "$(readlink "$link")" = "$target" ]; then
            debug "Symlink already exists: $link"
        else
            warning "$link is a symlink to another target; leaving it unchanged"
        fi
        return 0
    fi

    if [ -e "$link" ]; then
        warning "$link exists but is not a symlink to $target"
        return 0
    fi

    ln -sv "$target" "$link"
    success "Added symlink $link to $target"
}

replace_managed_symlink() {
    local new_target="$1"
    local link="$2"
    local managed_prefix="$3"
    local managed_suffix="$4"

    if [ -L "$link" ]; then
        local current_target
        current_target=$(readlink "$link")

        if [ "$current_target" = "$new_target" ]; then
            debug "Symlink already exists: $link"
            return 0
        fi

        case "$current_target" in
            "$managed_prefix"/*"$managed_suffix")
                if [ ! -e "$current_target" ]; then
                    rm -f "$link"
                    ln -sv "$new_target" "$link"
                    success "Migrated symlink $link from $current_target to $new_target"
                    return 0
                fi
                ;;
        esac

        warning "$link is a symlink to another target; leaving it unchanged"
        return 0
    fi

    symlink "$new_target" "$link"
}

prune_stale_managed_skill_links() {
    local source_root="$1"
    local dest_root="$2"
    local link current_target

    if [ ! -d "$dest_root" ]; then
        return 0
    fi

    find "$dest_root" -mindepth 1 -maxdepth 1 -type l -print |
        sort |
        while IFS= read -r link; do
            current_target=$(readlink "$link")

            case "$current_target" in
                "$source_root"/*)
                    if [ ! -e "$current_target" ]; then
                        rm -f "$link"
                        success "Removed stale managed skill symlink $link -> $current_target"
                    fi
                    ;;
            esac
        done
}

link_managed_skill_tree() {
    local source_root="$1"
    local dest_root="$2"
    local skill_file skill_dir skill_name

    mkdir -pv "$dest_root"
    prune_stale_managed_skill_links "$source_root" "$dest_root"

    if [ ! -d "$source_root" ]; then
        debug "Skill source root does not exist: $source_root"
        return 0
    fi

    find "$source_root" -mindepth 2 -maxdepth 2 -name SKILL.md -type f -print |
        sort |
        while IFS= read -r skill_file; do
            skill_dir=$(dirname "$skill_file")
            skill_name=$(basename "$skill_dir")
            replace_managed_symlink \
                "$skill_dir" \
                "$dest_root/$skill_name" \
                "$DOTFILES_DIR/config" \
                "/skills/$skill_name"
        done
}

clone_repo() {
    local repo="$1"
    local dest="$2"

    if [ ! -d "$dest" ]; then
        if git clone "$repo" "$dest"; then
            success "Repository cloned $repo to $dest"
        else
            error "Repository $repo cannot be cloned to $dest"
            return 1
        fi
    else
        debug "Repository already exists: $dest"
    fi
}

git_parallel_jobs() {
    local parallel_jobs="${GIT_PARALLEL_JOBS:-4}"
    local is_valid=0

    case "$parallel_jobs" in
        ""|*[!0-9]*)
            parallel_jobs=4
            is_valid=1
            ;;
    esac

    if [ "$parallel_jobs" -eq 0 ]; then
        parallel_jobs=4
        is_valid=1
    fi

    printf "%s\n" "$parallel_jobs"
    return "$is_valid"
}

git_parallel_log_label() {
    local label="$1"
    local safe_label

    safe_label=$(printf "%s" "$label" | tr -c "[:alnum:]_.-" "-")
    if [ -n "$safe_label" ]; then
        printf "%s\n" "$safe_label"
    else
        printf "task\n"
    fi
}

git_parallel_log_dir() {
    local task_kind="$1"
    local tmp_dir="${TMPDIR:-/tmp}"

    tmp_dir="${tmp_dir%/}"
    mktemp -d "$tmp_dir/dotfiles-git-$task_kind.XXXXXX"
}

git_parallel_wait_for_slot() {
    local parallel_jobs="$1"
    local running_jobs

    while true; do
        running_jobs=$(jobs -rp | wc -l | tr -d "[:space:]")
        if [ "$running_jobs" -lt "$parallel_jobs" ]; then
            return 0
        fi

        sleep 0.2
    done
}

git_parallel_start_task() {
    local task_index="$1"
    local task_label="$2"
    local log_dir="$3"
    local task_command="$4"
    local task_prefix safe_label log_file status_file label_file
    shift 4

    task_prefix=$(printf "%03d" "$task_index")
    safe_label=$(git_parallel_log_label "$task_label")
    log_file="$log_dir/$task_prefix-$safe_label.log"
    status_file="$log_dir/$task_prefix-$safe_label.status"
    label_file="$log_dir/$task_prefix-$safe_label.label"

    printf "%s\n" "$task_label" > "$label_file"

    (
        set +e
        "$task_command" "$@" > "$log_file" 2>&1
        task_status=$?
        printf "%s\n" "$task_status" > "$status_file"
        exit 0
    ) &
}

git_parallel_finish_tasks() {
    local log_dir="$1"
    local task_count="$2"
    local failed_count=0
    local task_index task_prefix label_file log_file status_file
    local task_label task_status

    if ! wait; then
        warning "One or more parallel git workers exited unexpectedly"
    fi

    for ((task_index = 1; task_index <= task_count; task_index++)); do
        task_prefix=$(printf "%03d" "$task_index")
        label_file=$(find "$log_dir" -name "$task_prefix-*.label" -print -quit)
        log_file=$(find "$log_dir" -name "$task_prefix-*.log" -print -quit)
        status_file=$(find "$log_dir" -name "$task_prefix-*.status" -print -quit)
        task_label="task $task_index"
        task_status=1

        if [ -n "$label_file" ]; then
            read -r task_label < "$label_file" || task_label="task $task_index"
        fi

        if [ -n "$status_file" ]; then
            read -r task_status < "$status_file" || task_status=1
        fi

        if [ "$task_status" -eq 0 ]; then
            success "$task_label"
        else
            failed_count=$((failed_count + 1))
            error "$task_label failed (log: $log_file)"
            if [ -n "$log_file" ] && [ -s "$log_file" ]; then
                sed "s/^/    /" "$log_file"
            fi
        fi
    done

    if [ "$failed_count" -eq 0 ]; then
        debug "Parallel git task logs: $log_dir"
        rm -rf "$log_dir"
    else
        warning "$failed_count parallel git task(s) failed; logs kept in $log_dir"
    fi

    return 0
}

clone_repos_parallel() {
    local parallel_jobs log_dir task_count repo dest label

    if [ "$#" -eq 0 ]; then
        return 0
    fi

    if [ $(( $# % 2 )) -ne 0 ]; then
        error "clone_repos_parallel expects repository/destination pairs"
        return 1
    fi

    if ! parallel_jobs=$(git_parallel_jobs); then
        warning "Invalid GIT_PARALLEL_JOBS=${GIT_PARALLEL_JOBS:-}, using $parallel_jobs"
    fi
    log_dir=$(git_parallel_log_dir "clone")
    task_count=0

    info "Cloning repositories in parallel (jobs: $parallel_jobs)"

    while [ "$#" -gt 0 ]; do
        repo="$1"
        dest="$2"
        shift 2

        task_count=$((task_count + 1))
        label="clone $(basename "$dest")"
        git_parallel_wait_for_slot "$parallel_jobs"
        git_parallel_start_task "$task_count" "$label" "$log_dir" clone_repo "$repo" "$dest"
    done

    git_parallel_finish_tasks "$log_dir" "$task_count"
}

update_repos_parallel() {
    local parallel_jobs log_dir task_count repo_path label

    if [ "$#" -eq 0 ]; then
        return 0
    fi

    if ! parallel_jobs=$(git_parallel_jobs); then
        warning "Invalid GIT_PARALLEL_JOBS=${GIT_PARALLEL_JOBS:-}, using $parallel_jobs"
    fi
    log_dir=$(git_parallel_log_dir "update")
    task_count=0

    info "Updating repositories in parallel (jobs: $parallel_jobs)"

    for repo_path in "$@"; do
        task_count=$((task_count + 1))
        label="update $(basename "$repo_path")"
        git_parallel_wait_for_slot "$parallel_jobs"
        git_parallel_start_task "$task_count" "$label" "$log_dir" update_repo "$repo_path"
    done

    git_parallel_finish_tasks "$log_dir" "$task_count"
}


brew_bundle_install() {
    local brewfile_path="$1"
    local description="$2"

    if [ ! -f "$brewfile_path" ]; then
        error "Brewfile not found: $brewfile_path"
        return 1
    fi

    if brew bundle install --file "$brewfile_path" --jobs auto --no-upgrade; then
        success "$description installed"
    else
        error "Failed to install $description"
        return 1
    fi
}

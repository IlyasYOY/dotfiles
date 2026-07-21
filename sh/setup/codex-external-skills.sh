#!/usr/bin/env bash

# This file is sourced by install.sh and update.sh after helpers.sh.

EXTERNAL_CODEX_SKILLS_MANIFEST="${EXTERNAL_CODEX_SKILLS_MANIFEST:-$DOTFILES_DIR/config/codex/external-skills.conf}"
EXTERNAL_CODEX_SKILLS_DATA_ROOT="${EXTERNAL_CODEX_SKILLS_DATA_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/ilyasyoy/codex-skills}"
EXTERNAL_CODEX_SKILLS_DEST_ROOT="${EXTERNAL_CODEX_SKILLS_DEST_ROOT:-$HOME/.codex/skills/IlyasYOY}"

external_skills_validate_commit() {
    local commit="$1"

    if [ "${#commit}" -eq 40 ]; then
        case "$commit" in
            *[!0-9a-f]*)
                ;;
            *)
                return 0
                ;;
        esac
    fi

    error "External skill commit must be a full lowercase 40-character SHA: $commit" >&2
    return 1
}

external_skills_validate_include_path() {
    local path="$1"

    case "$path" in
        ""|.|..|/*|../*|*/../*|*/..|*/|*//*|*,*|*'|'*)
            error "Invalid external skill include path: $path" >&2
            return 1
            ;;
    esac

    case "$path" in
        *$'\n'*|*$'\r'*|*$'\t'*)
            error "External skill include paths cannot contain control characters" >&2
            return 1
            ;;
    esac
}

external_skills_repo_key() {
    local repo="$1"
    local key

    key=${repo%.git}
    key=${key#https://}
    key=${key#http://}
    key=${key#ssh://}
    key=${key#git@}
    key=${key//:/-}
    key=${key//\//-}
    key=${key//[^A-Za-z0-9._-]/-}
    printf "%s\n" "$key"
}

external_skills_path_is_included() {
    local skill_path="$1"
    shift
    local include_path

    if [ "$#" -eq 0 ]; then
        return 0
    fi

    for include_path in "$@"; do
        if [ "$skill_path" = "$include_path" ]; then
            return 0
        fi
        case "$skill_path" in
            "$include_path"/*)
                return 0
                ;;
        esac
    done

    return 1
}

external_skills_discover_paths() {
    local repo_dir="$1"
    local commit="$2"
    shift 2
    local file skill_path existing_path include_path skill_count=0
    local -a skill_paths=()

    for include_path in "$@"; do
        external_skills_validate_include_path "$include_path" || return 1
    done

    while IFS= read -r file; do
        case "$file" in
            */SKILL.md)
                skill_path=${file%/SKILL.md}
                if external_skills_path_is_included "$skill_path" "$@"; then
                    for existing_path in "${skill_paths[@]+"${skill_paths[@]}"}"; do
                        case "$skill_path" in
                            "$existing_path"/*)
                                error "Nested external skills are not supported: $existing_path and $skill_path" >&2
                                return 1
                                ;;
                        esac
                        case "$existing_path" in
                            "$skill_path"/*)
                                error "Nested external skills are not supported: $skill_path and $existing_path" >&2
                                return 1
                                ;;
                        esac
                    done
                    skill_paths+=("$skill_path")
                    skill_count=$((skill_count + 1))
                fi
                ;;
        esac
    done < <(git -C "$repo_dir" ls-tree -r --name-only "$commit")

    if [ "$skill_count" -eq 0 ]; then
        error "No SKILL.md files matched the configured repository paths" >&2
        return 1
    fi

    printf "%s\n" "${skill_paths[@]}"
}

external_skills_read_name() {
    local skill_file="$1"

    awk '
        NR == 1 && $0 == "---" { in_frontmatter = 1; next }
        in_frontmatter && $0 == "---" { exit }
        in_frontmatter && /^name:[[:space:]]*/ {
            sub(/^name:[[:space:]]*/, "")
            gsub(/^['\''"]|['\''"]$/, "")
            print
            exit
        }
    ' "$skill_file"
}

external_skills_validate_tree() {
    local repo_dir="$1"
    local commit="$2"
    shift 2
    local skill_path mode object_type object_id entry

    for skill_path in "$@"; do
        while IFS=$' \t' read -r mode object_type object_id entry; do
            : "$object_id"
            if [ "$object_type" != "blob" ]; then
                error "External skill contains a non-file Git object: $skill_path/$entry" >&2
                return 1
            fi
            if [ "$mode" = "120000" ]; then
                error "External skill contains a symlink: $skill_path/$entry" >&2
                return 1
            fi
        done < <(git -C "$repo_dir" ls-tree -r "$commit" -- "$skill_path")
    done
}

external_skills_validate_checkout() {
    local checkout_dir="$1"
    shift
    local skill_path skill_name expected_name existing_name
    local -a skill_names=()

    for skill_path in "$@"; do
        if [ ! -f "$checkout_dir/$skill_path/SKILL.md" ]; then
            error "External skill is missing SKILL.md after checkout: $skill_path" >&2
            return 1
        fi

        skill_name=$(external_skills_read_name "$checkout_dir/$skill_path/SKILL.md")
        expected_name=$(basename "$skill_path")
        if [ -z "$skill_name" ] || [ "$skill_name" != "$expected_name" ]; then
            error "External skill name must match its directory: $skill_path (found '$skill_name')" >&2
            return 1
        fi
        case "$skill_name" in
            *[!a-z0-9._-]*|"")
                error "Invalid external skill name: $skill_name" >&2
                return 1
                ;;
        esac

        for existing_name in "${skill_names[@]+"${skill_names[@]}"}"; do
            if [ "$existing_name" = "$skill_name" ]; then
                error "Duplicate external skill name: $skill_name" >&2
                return 1
            fi
        done
        skill_names+=("$skill_name")
    done
}

external_skills_prepare_snapshot() {
    local repo="$1"
    local commit="$2"
    shift 2
    local repo_key repo_root snapshot_root stage_root resolved skill_path discovered_paths
    local -a all_skill_paths=() selected_skill_paths=()

    external_skills_validate_commit "$commit" || return 1
    repo_key=$(external_skills_repo_key "$repo")
    repo_root="$EXTERNAL_CODEX_SKILLS_DATA_ROOT/repositories/$repo_key"
    snapshot_root="$repo_root/$commit"

    if [ -d "$snapshot_root/.git" ]; then
        resolved=$(git -C "$snapshot_root" rev-parse HEAD)
        if [ "$resolved" != "$commit" ] ||
            [ -n "$(git -C "$snapshot_root" status --porcelain --untracked-files=all)" ]; then
            error "Cached external skill snapshot is not clean at $commit: $snapshot_root" >&2
            return 1
        fi
    else
        mkdir -p "$repo_root"
        stage_root=$(mktemp -d "$repo_root/.${commit}.XXXXXX")
        if ! git -C "$stage_root" init -q ||
            ! git -C "$stage_root" remote add origin "$repo" ||
            ! git -C "$stage_root" fetch --quiet --depth 1 origin "$commit"; then
            error "Failed to fetch external skills from $repo at $commit" >&2
            rm -rf "$stage_root"
            return 1
        fi

        resolved=$(git -C "$stage_root" rev-parse FETCH_HEAD)
        if [ "$resolved" != "$commit" ]; then
            error "Fetched external skill commit $resolved does not match requested commit $commit" >&2
            rm -rf "$stage_root"
            return 1
        fi

        discovered_paths=$(external_skills_discover_paths "$stage_root" "$commit") || {
            rm -rf "$stage_root"
            return 1
        }
        while IFS= read -r skill_path; do
            all_skill_paths+=("$skill_path")
        done <<< "$discovered_paths"

        git -C "$stage_root" sparse-checkout init --cone
        git -C "$stage_root" sparse-checkout set "${all_skill_paths[@]}"
        git -C "$stage_root" checkout --quiet --detach "$commit"
        mv "$stage_root" "$snapshot_root"
    fi

    discovered_paths=$(external_skills_discover_paths "$snapshot_root" "$commit" "$@") || return 1
    while IFS= read -r skill_path; do
        selected_skill_paths+=("$skill_path")
    done <<< "$discovered_paths"

    external_skills_validate_tree "$snapshot_root" "$commit" "${selected_skill_paths[@]}" || return 1
    external_skills_validate_checkout "$snapshot_root" "${selected_skill_paths[@]}" || return 1
    printf "%s\n" "$snapshot_root"
}

external_skills_selected_paths() {
    local snapshot_root="$1"
    local commit="$2"
    shift 2
    external_skills_discover_paths "$snapshot_root" "$commit" "$@"
}

external_skills_link_snapshot() {
    local repo="$1"
    local commit="$2"
    local snapshot_root="$3"
    shift 3
    local repo_key skill_path skill_name link current_target desired
    local -a desired_names=()

    repo_key=$(external_skills_repo_key "$repo")
    mkdir -pv "$EXTERNAL_CODEX_SKILLS_DEST_ROOT"

    for skill_path in "$@"; do
        skill_name=$(basename "$skill_path")
        desired_names+=("$skill_name")
        link="$EXTERNAL_CODEX_SKILLS_DEST_ROOT/$skill_name"
        desired="$snapshot_root/$skill_path"

        if [ -L "$link" ]; then
            current_target=$(readlink "$link")
            case "$current_target" in
                "$EXTERNAL_CODEX_SKILLS_DATA_ROOT/repositories/$repo_key"/*)
                    ;;
                *)
                    error "External skill name collides with another managed skill: $skill_name" >&2
                    return 1
                    ;;
            esac
        elif [ -e "$link" ]; then
            error "External skill name collides with an existing path: $link" >&2
            return 1
        fi

        if [ ! -d "$desired" ]; then
            error "External skill target does not exist: $desired" >&2
            return 1
        fi
    done

    if [ -d "$EXTERNAL_CODEX_SKILLS_DEST_ROOT" ]; then
        find "$EXTERNAL_CODEX_SKILLS_DEST_ROOT" -mindepth 1 -maxdepth 1 -type l -print |
            sort |
            while IFS= read -r link; do
                current_target=$(readlink "$link")
                case "$current_target" in
                    "$EXTERNAL_CODEX_SKILLS_DATA_ROOT/repositories/$repo_key"/*)
                        skill_name=$(basename "$link")
                        if ! printf "%s\n" "${desired_names[@]}" | grep -qxF "$skill_name"; then
                            rm -f "$link"
                            success "Removed excluded external Codex skill $skill_name"
                        fi
                        ;;
                esac
            done
    fi

    for skill_path in "$@"; do
        skill_name=$(basename "$skill_path")
        link="$EXTERNAL_CODEX_SKILLS_DEST_ROOT/$skill_name"
        desired="$snapshot_root/$skill_path"
        if [ -L "$link" ] && [ "$(readlink "$link")" = "$desired" ]; then
            debug "External Codex skill already installed: $skill_name"
            continue
        fi
        rm -f "$link"
        ln -s "$desired" "$link"
        success "Installed external Codex skill $skill_name at $commit"
    done
}

install_skills_from_repo() {
    local repo="$1"
    local commit="$2"
    shift 2
    local snapshot_root skill_path discovered_paths
    local -a selected_skill_paths=()

    snapshot_root=$(external_skills_prepare_snapshot "$repo" "$commit" "$@") || return 1
    discovered_paths=$(external_skills_selected_paths "$snapshot_root" "$commit" "$@") || return 1
    while IFS= read -r skill_path; do
        selected_skill_paths+=("$skill_path")
    done <<< "$discovered_paths"

    external_skills_link_snapshot \
        "$repo" \
        "$commit" \
        "$snapshot_root" \
        "${selected_skill_paths[@]}"
}

external_skills_update_manifest_commit() {
    local repo="$1"
    local new_commit="$2"
    local tmp_file

    tmp_file=$(mktemp "$EXTERNAL_CODEX_SKILLS_MANIFEST.tmp.XXXXXX")
    awk -F '|' -v OFS='|' -v repo="$repo" -v commit="$new_commit" '
        $1 == repo { $3 = commit; found = 1 }
        { print }
        END { if (!found) exit 1 }
    ' "$EXTERNAL_CODEX_SKILLS_MANIFEST" > "$tmp_file" || {
        rm -f "$tmp_file"
        error "Could not update external skill manifest for $repo" >&2
        return 1
    }
    mv "$tmp_file" "$EXTERNAL_CODEX_SKILLS_MANIFEST"
}

external_skills_print_excluded() {
    local snapshot_root="$1"
    local commit="$2"
    shift 2
    local skill_path
    local -a selected_paths=()

    while IFS= read -r skill_path; do
        selected_paths+=("$skill_path")
    done < <(external_skills_discover_paths "$snapshot_root" "$commit" "$@")

    while IFS= read -r skill_path; do
        if ! printf "%s\n" "${selected_paths[@]}" | grep -qxF "$skill_path"; then
            printf "  - %s\n" "$skill_path"
        fi
    done < <(external_skills_discover_paths "$snapshot_root" "$commit")
}

review_and_update_skills_from_repo() {
    local repo="$1"
    local old_commit="$2"
    local new_commit="$3"
    shift 3
    local old_snapshot new_snapshot skill_path status excluded_paths
    local -a diff_paths=()

    external_skills_validate_commit "$old_commit" || return 1
    external_skills_validate_commit "$new_commit" || return 1
    if [ "$old_commit" = "$new_commit" ]; then
        debug "External skills already current for $repo at $old_commit"
        return 0
    fi

    old_snapshot=$(external_skills_prepare_snapshot "$repo" "$old_commit" "$@") || return 1
    new_snapshot=$(external_skills_prepare_snapshot "$repo" "$new_commit" "$@") || return 1
    git -C "$new_snapshot" fetch --quiet --depth 1 origin "$old_commit"

    while IFS= read -r skill_path; do
        diff_paths+=("$skill_path")
    done < <(
        {
            external_skills_selected_paths "$old_snapshot" "$old_commit" "$@"
            external_skills_selected_paths "$new_snapshot" "$new_commit" "$@"
        } | sort -u
    )

    info "External Codex skill update available"
    printf "Repository: %s\nCurrent:    %s\nCandidate:  %s\n" \
        "$repo" "$old_commit" "$new_commit"
    if [ "$#" -gt 0 ]; then
        excluded_paths=$(external_skills_print_excluded "$new_snapshot" "$new_commit" "$@") || return 1
        if [ -n "$excluded_paths" ]; then
            printf "Excluded skill directories discovered at the candidate commit:\n%s\n" \
                "$excluded_paths"
        fi
    fi

    git -C "$new_snapshot" diff --stat "$old_commit" "$new_commit" -- "${diff_paths[@]}" || return 1
    if git -C "$new_snapshot" diff --quiet "$old_commit" "$new_commit" -- "${diff_paths[@]}"; then
        info "Selected skill contents are unchanged."
    else
        git -C "$new_snapshot" --no-pager diff --no-ext-diff "$old_commit" "$new_commit" -- "${diff_paths[@]}" || {
            status=$?
            if [ "$status" -ne 1 ]; then
                return "$status"
            fi
        }
    fi
    if ! confirm_update "Accept external Codex skill update from $repo"; then
        return 2
    fi

    install_skills_from_repo "$repo" "$new_commit" "$@" || return 1
    external_skills_update_manifest_commit "$repo" "$new_commit"
}

external_skills_manifest_rows() {
    local repo tracked_ref commit include_paths extra

    if [ ! -f "$EXTERNAL_CODEX_SKILLS_MANIFEST" ]; then
        error "External Codex skills manifest does not exist: $EXTERNAL_CODEX_SKILLS_MANIFEST" >&2
        return 1
    fi

    while IFS='|' read -r repo tracked_ref commit include_paths extra; do
        case "$repo" in
            ""|'#'*)
                continue
                ;;
        esac
        if [ -n "$extra" ] || [ -z "$tracked_ref" ] || [ -z "$commit" ]; then
            error "Malformed external Codex skill manifest row for $repo" >&2
            return 1
        fi
        external_skills_validate_commit "$commit" || return 1
        printf "%s|%s|%s|%s\n" "$repo" "$tracked_ref" "$commit" "$include_paths"
    done < "$EXTERNAL_CODEX_SKILLS_MANIFEST"
}

install_external_codex_skills() {
    local repo tracked_ref commit include_paths path manifest_rows
    local -a paths=()

    info "🤖 Installing pinned external Codex skills..."
    manifest_rows=$(external_skills_manifest_rows) || return 1
    while IFS='|' read -r repo tracked_ref commit include_paths <&3; do
        paths=()
        if [ -n "$include_paths" ]; then
            while IFS= read -r path; do
                paths+=("$path")
            done < <(printf "%s\n" "$include_paths" | tr ',' '\n')
        fi
        debug "Installing external Codex skills from tracked ref $tracked_ref"
        if [ -n "$include_paths" ]; then
            install_skills_from_repo "$repo" "$commit" "${paths[@]}"
        else
            install_skills_from_repo "$repo" "$commit"
        fi
    done 3<<< "$manifest_rows"
}

update_external_codex_skills() {
    local repo tracked_ref commit include_paths path candidate status manifest_rows
    local -a paths=()

    info "🤖 Checking external Codex skill updates..."
    manifest_rows=$(external_skills_manifest_rows) || return 1
    while IFS='|' read -r repo tracked_ref commit include_paths <&3; do
        paths=()
        if [ -n "$include_paths" ]; then
            while IFS= read -r path; do
                paths+=("$path")
            done < <(printf "%s\n" "$include_paths" | tr ',' '\n')
        fi

        candidate=$(git ls-remote "$repo" "refs/heads/$tracked_ref" | awk 'NR == 1 { print $1 }')
        external_skills_validate_commit "$candidate" || return 1
        if [ -n "$include_paths" ]; then
            if review_and_update_skills_from_repo \
                "$repo" "$commit" "$candidate" "${paths[@]}"; then
                status=0
            else
                status=$?
            fi
        else
            if review_and_update_skills_from_repo \
                "$repo" "$commit" "$candidate"; then
                status=0
            else
                status=$?
            fi
        fi

        if [ "$status" -eq 0 ]; then
            continue
        fi
        if [ "$status" -eq 2 ]; then
            warning "Declined external Codex skill update from $repo"
            continue
        fi
        return "$status"
    done 3<<< "$manifest_rows"
}

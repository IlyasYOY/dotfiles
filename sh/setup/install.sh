#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$(dirname "$0")/helpers.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/codex-external-skills.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/mac.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/raspberry-pi.sh"

setup_basic_directories() {
    info "📁 Creating basic directories..."
    mkdir -pv "$PERSONAL_PROJECTS_DIR" "$WORK_PROJECTS_DIR"
}

setup_my_project() {
    info "👨💻 Setting up personal projects..."

    local -a plugin_clone_args=()
    local plugin
    for plugin in "${PERSONAL_NVIM_PLUGIN_REPOS[@]}"; do
        plugin_clone_args+=(
            "git@github.com:IlyasYOY/$plugin.git"
            "$PERSONAL_PROJECTS_DIR/$plugin"
        )
    done

    clone_repos_parallel "${plugin_clone_args[@]}"

    clone_repos_parallel \
        "git@github.com:IlyasYOY/monotask.git" "$PERSONAL_PROJECTS_DIR/monotask" \
        "git@github.com:IlyasYOY/IlyasYOY.git" "$PERSONAL_PROJECTS_DIR/IlyasYOY" \
        "git@github.com:IlyasYOY/singularity-mcp.git" "$PERSONAL_PROJECTS_DIR/singularity-mcp" \
        "git@github.com:IlyasYOY/t-invest-mcp.git" "$PERSONAL_PROJECTS_DIR/t-invest-mcp"
}

setup_notes() {
    info "📝 Setting up notes..."

    mkdir -pv "$KB_DIR"
    if [ ! -d "$KB_DIR/.git" ]; then
        git -C "$KB_DIR" init
        success "Initialized kb-store git repo"
    fi
}

setup_links_to_config_files() {
    info "⚙️ Setting up config links..."
    local config_dir="$HOME/.config"
    mkdir -pv "$config_dir"
    mkdir -pv "$HOME/.gnupg"

    # Main config links
    symlink "$DOTFILES_DIR/config/nvim" "$config_dir/nvim"
    symlink "$DOTFILES_DIR/config/nvim-minimal" "$config_dir/nvim-minimal"
    if is_mac; then
        symlink "$DOTFILES_DIR/config/wezterm" "$config_dir/wezterm"
        symlink "$DOTFILES_DIR/config/hammerspoon" "$HOME/.hammerspoon"
    fi
    symlink "$DOTFILES_DIR/config/gnupg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
    setup_mac_pinentry_defaults
    if command -v gpgconf >/dev/null 2>&1; then
        gpgconf --kill gpg-agent && gpgconf --launch gpg-agent && debug "restart gpg-agent"
    else
        debug "gpgconf is not available yet, skipping gpg-agent restart"
    fi


    # Git config
    mkdir -pv "$config_dir/git"
    symlink "$DOTFILES_DIR/config/.gitignore-global" "$config_dir/git/ignore"

    # Home directory links
    symlink "$DOTFILES_DIR/config/.golangci.yml" "$HOME_DIR/.golangci.yml"
    symlink "$DOTFILES_DIR/config/.tmux.conf" "$HOME_DIR/.tmux.conf"
    symlink "$DOTFILES_DIR/config/.vimrc" "$HOME_DIR/.vimrc"
    if is_mac; then
        symlink "$DOTFILES_DIR/config/.amethyst.yml" "$HOME_DIR/.amethyst.yml"
    fi
}

setup_platform_dependencies() {
    if is_mac; then
        setup_mac_using_brew
        setup_mac_using_brew_cask
        setup_mac_using_app_store

        if confirm_update "Apply macOS defaults"; then
            setup_mac_defaults

            if confirm_update "Restart macOS UI services"; then
                restart_mac_ui_services
            fi
        fi

        return 0
    fi

    if is_raspberry_pi; then
        setup_raspberry_pi
        return 0
    fi

    warning "No platform-specific dependency bootstrap is configured for this host"
}



setup_shell_rc() {
    local rc_file
    rc_file=$(shell_rc_file)

    if is_raspberry_pi; then
        info "🐚 Configuring .bashrc..."
    else
        info "🐚 Configuring .zshrc..."
    fi

    local lines=(
        "export ILYASYOY_DOTFILES_DIR=\"$DOTFILES_DIR\""
        "source \$ILYASYOY_DOTFILES_DIR/sh/helpers.sh"
        "source \$ILYASYOY_DOTFILES_DIR/sh/exports.sh"
        "source \$ILYASYOY_DOTFILES_DIR/sh/aliases.sh"
    )

    if is_raspberry_pi; then
        lines=(
            "export ILYASYOY_DOTFILES_DIR=\"$DOTFILES_DIR\""
            "source <(fzf --bash)"
            "source \$ILYASYOY_DOTFILES_DIR/sh/helpers.sh"
            "source \$ILYASYOY_DOTFILES_DIR/sh/exports.sh"
            "source \$ILYASYOY_DOTFILES_DIR/sh/aliases.sh"
        )
    else
        lines=(
            "export ILYASYOY_DOTFILES_DIR=\"$DOTFILES_DIR\""
            "source <(fzf --zsh)"
            "source \$ILYASYOY_DOTFILES_DIR/sh/helpers.sh"
            "source \$ILYASYOY_DOTFILES_DIR/sh/exports.sh"
            "source \$ILYASYOY_DOTFILES_DIR/sh/aliases.sh"
        )
    fi

    for line in "${lines[@]}"; do
        add_line "$line" "$rc_file"
    done
}

setup_sdkman() {
    info "☕ Installing SDKMAN..."

    if [ ! -d "$HOME/.sdkman" ]; then
        curl -s "https://get.sdkman.io" | bash
        success "SDKMAN installed"
    else
        debug "SDKMAN already installed"
    fi

    local sdkman_config
    sdkman_config=$'export SDKMAN_DIR="$HOME/.sdkman"\n[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"'

    add_block "$(shell_rc_file)" \
        "ilyasyoy sdkman config" \
        "$sdkman_config"
}

setup_node_version_manager() {
    info "⬢ Installing fnm (Fast Node Manager)..."

    # fnm configuration
    local rc_file shell
    rc_file=$(shell_rc_file)
    shell=$(shell_name)
    local fnm_config="eval \"\$(fnm env --use-on-cd --shell $shell)\""

    add_block "$rc_file" \
        "ilyasyoy fnm config" \
        "$fnm_config"

    if ! command -v fnm >/dev/null 2>&1; then
        warning "fnm is not available in the current shell yet; install Node.js after opening a new shell"
        return 0
    fi

    eval "$(fnm env --shell bash)"

    if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
        fnm install --lts --use
        local node_version
        node_version=$(fnm current)
        if [ -n "$node_version" ]; then
            fnm default "$node_version"
        fi
        success "Node.js and npm installed with fnm"
    else
        debug "Node.js and npm already installed"
    fi
}

setup_go_version_manager() {
    info "🐹 Installing GVM..."
    if [ ! -d "$HOME/.gvm" ]; then
        bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
        # Source GVM immediately
        # shellcheck source=/dev/null
        [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

        success "GVM installed"
    else 
        debug "GVM already installed"
    fi

    # GVM configuration
    local gvm_config=$'_gvm_lazy_load() {\n    unset -f gvm\n    [[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"\n    "$@"\n}\ngvm() { _gvm_lazy_load gvm "$@"; }'

    add_block "$(shell_rc_file)" \
        "ilyasyoy gvm config" \
        "$gvm_config"
}

setup_go_binaries() {
    info "🎯 Installing Go binaries..."

    if ! command -v go >/dev/null 2>&1; then
        warning "Go is not installed yet; skipping Go binary installation"
        return 0
    fi

    if go install github.com/IlyasYOY/monotask/cmd/monotask@latest; then
        success "monotask installed"
    else
        error "Failed to install monotask"
        return 1
    fi

    if go install github.com/IlyasYOY/singularity-mcp/cmd/singularity-mcp@latest; then
        success "singularity-mcp installed"
    else
        error "Failed to install singularity-mcp"
        return 1
    fi

    if make -C "$PERSONAL_PROJECTS_DIR/t-invest-mcp" install; then
        success "t-invest-mcp installed"
    else
        error "Failed to install t-invest-mcp"
        return 1
    fi
}

setup_oh_my_zsh() {
    if ! is_mac; then
        info "This is not mac, skipping Oh My Zsh installation"
        return 0
    fi

    info "🚀 Installing Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        success "Oh My Zsh installed"
    else
        debug "Oh My Zsh already installed"
    fi
}

setup_git_config() {
    info "🔧 Configuring Git..."

    git config --global alias.st "status"
    git config --global alias.c "commit"
    git config --global alias.co "checkout"
    git config --global alias.lg "log --all --decorate --graph --oneline"
    git config --global diff.algorithm histogram
    git config --global core.quotePath false
}

setup_tmux_plugin_manger() {
    info "🖥️ Setting up Tmux Plugin Manager..."

    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$tpm_dir" ]; then
        if clone_repo "https://github.com/tmux-plugins/tpm" "$tpm_dir"; then
            "$tpm_dir/bin/install_plugins"
            success "TPM installed"
        fi
    else
        debug "TPM already installed"
    fi
}

setup_pass() {
    info "💻🔐 pass password-store..."

    clone_repo "git@github.com:IlyasYOY/password-store.git" "$HOME/.password-store/" || true
}

setup_codex() {
    info "🤖 Setting up Codex..."

    info "🤖 Setting up Codex instructions..."
    local codex_config_dir="$HOME/.codex"
    mkdir -pv "$codex_config_dir"
    symlink "$DOTFILES_DIR/config/codex/AGENTS.md" "$codex_config_dir/AGENTS.md"

    local codex_root_config
    codex_root_config=$(cat <<'EOF'
model = "gpt-5.6-sol"
personality = "pragmatic"
model_reasoning_effort = "medium"
plan_mode_reasoning_effort = "high"
sandbox_mode = "workspace-write"
approval_policy = "on-request"
approvals_reviewer = "auto_review"
service_tier = "default"
suppress_unstable_features_warning = true
EOF
)
    add_toml_root_block \
        "$codex_config_dir/config.toml" \
        "ilyasyoy codex root config" \
        "$codex_root_config"

    local codex_tui_config
    codex_tui_config=$(cat <<'EOF'
notifications = true
notification_method = "bel"
notification_condition = "always"
status_line = ["model-with-reasoning", "current-dir", "five-hour-limit", "weekly-limit", "context-remaining"]
session_picker_view = "comfortable"
pet = "disabled"
EOF
)
    add_toml_table_block \
        "$codex_config_dir/config.toml" \
        "tui" \
        "ilyasyoy codex tui config" \
        "$codex_tui_config"

    info "🤖 Setting up Codex rules..."
    local codex_rules_dir="$codex_config_dir/rules"
    mkdir -pv "$codex_rules_dir"
    symlink "$DOTFILES_DIR/config/codex/rules/default.rules" "$codex_rules_dir/default.rules"

    local codex_notice_config
    codex_notice_config=$(cat <<'EOF'
hide_rate_limit_model_nudge = true
fast_default_opt_out = true
EOF
)
    add_toml_table_block \
        "$codex_config_dir/config.toml" \
        "notice" \
        "ilyasyoy codex notice config" \
        "$codex_notice_config"

    local codex_sandbox_config
    codex_sandbox_config=$(cat <<EOF
network_access = false
writable_roots = [
    "$DOTFILES_DIR",
    "$KB_DIR",
]
EOF
)
    add_toml_table_block \
        "$codex_config_dir/config.toml" \
        "sandbox_workspace_write" \
        "ilyasyoy codex sandbox config" \
        "$codex_sandbox_config"

    local codex_features_config
    codex_features_config=$(cat <<'EOF'
js_repl = false
default_mode_request_user_input = true
memories = true
EOF
)
    add_toml_table_block \
        "$codex_config_dir/config.toml" \
        "features" \
        "ilyasyoy codex features config" \
        "$codex_features_config"

    local codex_memories_config
    codex_memories_config=$(cat <<'EOF'
generate_memories = true
use_memories = true
disable_on_external_context = false
EOF
)
    add_toml_table_block \
        "$codex_config_dir/config.toml" \
        "memories" \
        "ilyasyoy codex memories config" \
        "$codex_memories_config"

    local codex_singularity_mcp_config
    codex_singularity_mcp_config=$(cat <<EOF
command = "$HOME/go/bin/singularity-mcp"
env_vars = ["SINGULARITY_TOKEN"]
startup_timeout_sec = 10
EOF
)
    add_toml_table_block \
        "$codex_config_dir/config.toml" \
        "mcp_servers.singularity" \
        "ilyasyoy codex singularity mcp config" \
        "$codex_singularity_mcp_config"

    local codex_t_invest_mcp_config
    codex_t_invest_mcp_config=$(cat <<EOF
command = "$HOME/go/bin/t-invest-mcp"
env_vars = [
    "T_INVEST_TOKEN",
    "T_INVEST_ENV",
    "T_INVEST_ACCOUNT_ID",
    "T_INVEST_TIMEOUT",
    "T_INVEST_MAX_RESPONSE_BYTES",
    "T_INVEST_APP_NAME",
]
startup_timeout_sec = 10
EOF
)
    add_toml_table_block \
        "$codex_config_dir/config.toml" \
        "mcp_servers.t-invest" \
        "ilyasyoy codex t-invest mcp config" \
        "$codex_t_invest_mcp_config"

    local codex_trusted_project_config
    codex_trusted_project_config=$(cat <<'EOF'
trust_level = "trusted"
EOF
)
    add_toml_table_block \
        "$codex_config_dir/config.toml" \
        "projects.\"$DOTFILES_DIR\"" \
        "ilyasyoy codex trusted dotfiles project" \
        "$codex_trusted_project_config"
    add_toml_table_block \
        "$codex_config_dir/config.toml" \
        "projects.\"$KB_DIR\"" \
        "ilyasyoy codex trusted notes project" \
        "$codex_trusted_project_config"
    add_toml_table_block \
        "$codex_config_dir/config.toml" \
        "projects.\"$PERSONAL_PROJECTS_DIR\"" \
        "ilyasyoy codex trusted personal projects" \
        "$codex_trusted_project_config"

    info "🤖 Setting up Codex skills..."
    local codex_skills_dir="$codex_config_dir/skills"
    local codex_namespace_dir="$codex_skills_dir/IlyasYOY"
    mkdir -pv "$codex_skills_dir"

    if [ -L "$codex_namespace_dir" ]; then
        local current_target
        current_target=$(readlink "$codex_namespace_dir")
        if [ "$current_target" = "$DOTFILES_DIR/config/codex/skills" ]; then
            rm -f "$codex_namespace_dir"
            success "Replaced legacy Codex skills namespace symlink"
        else
            warning "$codex_namespace_dir is a symlink to another target; leaving Codex skills unchanged"
            return 0
        fi
    fi

    if [ -e "$codex_namespace_dir" ] && [ ! -d "$codex_namespace_dir" ]; then
        warning "$codex_namespace_dir exists but is not a directory; leaving Codex skills unchanged"
        return 0
    fi

    mkdir -pv "$codex_namespace_dir"

    link_managed_skill_tree "$DOTFILES_DIR/config/agent/skills" "$codex_namespace_dir"
    link_managed_skill_tree "$DOTFILES_DIR/config/codex/skills" "$codex_namespace_dir"
    install_external_codex_skills
}

setup_opencode() {
    info "🤖 Setting up OpenCode..."

    local opencode_config_dir="$HOME/.config/opencode"
    mkdir -pv "$opencode_config_dir"

    symlink \
        "$DOTFILES_DIR/config/opencode/AGENTS.md" \
        "$opencode_config_dir/AGENTS.md"
    configure_opencode_json \
        "$DOTFILES_DIR/config/opencode/opencode.json" \
        "$opencode_config_dir/opencode.json"
    symlink "$DOTFILES_DIR/config/opencode/commands" "$opencode_config_dir/commands"
    symlink "$DOTFILES_DIR/config/opencode/plugins" "$opencode_config_dir/plugins"

    info "🤖 Setting up OpenCode skills..."
    local opencode_skills_dir="$opencode_config_dir/skills"
    mkdir -pv "$opencode_skills_dir"

    link_managed_skill_tree "$DOTFILES_DIR/config/agent/skills" "$opencode_skills_dir"
    link_managed_skill_tree "$DOTFILES_DIR/config/opencode/skills" "$opencode_skills_dir"
}

main() {
    setup_basic_directories
    setup_platform_dependencies
    setup_notes
    setup_links_to_config_files
    setup_shell_rc
    setup_git_config
    setup_sdkman
    setup_go_version_manager
    setup_my_project
    setup_go_binaries
    setup_node_version_manager
    setup_oh_my_zsh
    setup_tmux_plugin_manger
    setup_pass

    setup_codex
    setup_opencode

    success "🎉 Setup completed successfully!"
    info "Some changes might require a new shell session or system restart"
}

main "$@"

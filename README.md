# Dotfiles

Personal workstation bootstrap and the top-level orchestrator for my development
environment.

This repository owns operating-system packages, shell startup, terminal and
desktop configuration, language version managers, and coordination of two
independent workbench repositories:

- [`nvim-workbench`](https://github.com/IlyasYOY/nvim-workbench) — Neovim
  configuration and personal plugin development;
- [`agent-workbench`](https://github.com/IlyasYOY/agent-workbench) — Codex and
  OpenCode instructions, skills, commands, plugins, and config-review
  workflows.

Both workbench repositories follow their upstream `main` branch. They own
their own installation, dependency updates, and canonical checks.

> [!WARNING]
> This is a personal, opinionated setup. The bootstrap assumes my project
> layout under `~/Projects/IlyasYOY`, manages shell startup files, clones
> personal repositories, and contains macOS- and Raspberry Pi-specific setup.

## Platform support

- macOS packages come from `Brewfile.mac` and `Brewfile.mac.cask`; desktop
  configuration includes WezTerm, Hammerspoon, and Amethyst.
- Raspberry Pi OS and compatible Debian systems use the smaller
  `Brewfile.raspberry-pi` plus apt-based bootstrap.

## Repository contents

- `sh/setup` — install, update, platform bootstrap, and workbench orchestration.
- `sh/helpers.sh`, `sh/exports.sh`, `sh/aliases.sh` — interactive shell setup.
- `config/wezterm`, `config/hammerspoon`, `config/gnupg`, `config/worktrunk`,
  `config/.tmux.conf`, `config/.amethyst.yml`, `config/.vimrc` — workstation
  configuration.
- `Brewfile.*` — platform package manifests.
- `bin` — small personal executable utilities.
- `tests` — orchestration contract tests.

Neovim and agent-tooling sources intentionally do not live here.

## Installation

```bash
mkdir -pv ~/Projects/IlyasYOY
cd ~/Projects/IlyasYOY
git clone git@github.com:IlyasYOY/dotfiles.git dotfiles
cd dotfiles
make install
```

`make install`:

1. creates the personal and work project directories;
2. installs platform packages;
3. links terminal, desktop, Git, GnuPG, and shell configuration;
4. configures SDKMAN, GVM, fnm, tmux TPM, and password-store;
5. clones other personal tools used by the workstation;
6. clones and calls `make install` in both workbench repositories.

The install also configures Worktrunk's shell integration. The update flow
refreshes that integration after package upgrades so its shell wrapper stays
compatible with the installed Worktrunk version.

The workbench installation can be run independently:

```bash
make install-workbenches
```

Default checkout locations are:

- `~/Projects/IlyasYOY/nvim-workbench`
- `~/Projects/IlyasYOY/agent-workbench`

Override them with `ILYASYOY_NVIM_WORKBENCH_DIR` and
`ILYASYOY_AGENT_WORKBENCH_DIR`.

`nvim-workbench` installs `~/.config/nvim`. The former
`~/.config/nvim-minimal` setup is no longer managed.

`agent-workbench` installs managed Codex/OpenCode instructions and extensions,
but does not edit `~/.codex/config.toml` or
`~/.config/opencode/opencode.json`. Run its repository-local `$setup-codex` or
`$setup-opencode` skill to review and reconcile those files.

## Updating

```bash
make update
```

The main update refreshes operating-system packages, tracked personal
repositories, workbenches, tmux plugins, and Go tools. Each workbench follows
its configured upstream branch and then updates the dependencies it owns.

To update only the workbenches:

```bash
make update-workbenches
```

Third-party Codex skills remain pinned to exact commits inside
`agent-workbench`; its update flow shows a diff and requires confirmation
before changing an accepted pin.

## Agent monitoring in tmux

[tmux-scout](https://github.com/qeesung/tmux-scout) opens an agent picker with
`prefix + O`; `prefix + w` remains the normal window tree.
Enter jumps to the selected agent, Esc closes the picker, Ctrl-R refreshes
it, and Ctrl-T toggles automatic refresh. The status bar shows waiting, busy,
and done counts (plus idle when present); clicking the widget opens the picker.

The picker fills the tmux client area with a full-width agent list and no preview.
The local `bin/tmux-scout-picker` launcher overrides fzf options only for Scout;
installed plugin files stay unchanged. Reload `~/.tmux.conf` to apply changes.
To restore Scout's original layout, remove the two local binding overrides
after TPM initialization and reload the config.

`make check` covers the launcher contract. With tmux running and at least one
Scout agent available, run the optional live UI check with
`uv run --with pyte python tests/manual_tmux_scout_picker.py`.

Install the plugin with TPM (`prefix + I`), then configure **only Codex**:

```bash
~/.tmux/plugins/tmux-scout/scripts/setup.sh install --codex
~/.tmux/plugins/tmux-scout/scripts/setup.sh status --codex
~/.tmux/plugins/tmux-scout/scripts/setup.sh doctor
```

Back up `~/.codex/config.toml` and any existing `~/.codex/hooks.json` first.
The upstream installer rewrites TOML formatting, adds lifecycle hooks and trust
entries, and wraps the existing `notify` command (saved in
`~/.tmux-scout/codex-original-notify.json`). Review the resulting diff and
preserve unrelated settings and comments. Hook installation is deliberately
separate from `make install`. Start a new Codex session to load the hooks.

Scout uses Node.js and fzf, captures the Node PATH when loaded (including fnm),
and runs a tmux-owned background monitor. Reload tmux from a shell with Node
available after changing Node versions. Runtime data lives in `~/.tmux-scout`.

To remove the integration while the plugin is still installed:

```bash
~/.tmux/plugins/tmux-scout/scripts/setup.sh uninstall --codex
tmux set-option -g @scout-watchdog off
~/.tmux/plugins/tmux-scout/scripts/setup.sh watcher stop
tmux set-hook -gu 'pane-focus-in[9909]'
tmux unbind-key O
tmux bind-key -T root MouseDown1Status switch-client -t =
```

Verify that the original `notify` command was restored. Remove the Scout plugin
declaration, `@scout-key`, widget, and local picker binding overrides from the
tmux config before reloading it.
Restore `status-interval` to its previous value if desired. Remove only Scout's
feature-flag changes using the backup as a reference; preserve later Codex edits.

## Git worktrees

[Worktrunk](https://worktrunk.dev/) provides the workstation's Git worktree
workflow:

```bash
wt switch -c feature/auth --base=@  # create from the current HEAD
wt switch feature/auth             # open an existing branch worktree
wt switch pr:123                    # open a GitHub pull request worktree
wt list                             # inspect all worktrees
wt merge                            # squash, rebase, merge, and clean up
```

New worktrees use Worktrunk's default sibling path,
`../<repo>.<sanitized-branch>`. Existing Git worktrees remain usable without
being moved. A blocking `pre-start` hook copies lightweight ignored files from
the primary worktree before entering a new one; use `--no-hooks` to skip that
copy for a single `wt switch` invocation. Dependency, build, and virtual
environment directories are excluded from copying.

`wt merge` intentionally uses Worktrunk's native workflow: it includes
uncommitted changes, generates a commit message through Codex, squashes and
rebases onto the target, then removes the merged worktree and branch. Use
ordinary `git pull` commands for remote updates; Worktrunk does not replace
Git's pull and sync operations.

## Local checks

```bash
make check
make check-lua
make check-shell
make check-python
```

`make check` is the same first-pass check used by CI. It validates the
remaining Lua and shell configuration plus the workbench orchestration
contract. Run `make check` inside each workbench for its own static and runtime
checks.

## Personal integration points

- Project roots default to `~/Projects/IlyasYOY`, `~/Projects/Work`, and
  `~/Projects/kb-store`.
- `GIT_PARALLEL_JOBS` controls parallel checkout updates.
- T-Invest MCP is built from `~/Projects/IlyasYOY/t-invest-mcp`; token values
  remain environment variables and are never stored here.
- Task workflows in `kb-store` use Google Tasks through Computer Use in the
  signed-in browser; no task-service API token is required.
- The shell alias `nvimconfig` opens the configuration installed by
  `nvim-workbench`.

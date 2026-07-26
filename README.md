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

- macOS packages come from `Brewfile.mac`, `Brewfile.mac.cask`, and
  `Brewfile.mac.mas`; desktop configuration includes WezTerm, Hammerspoon, and
  Amethyst.
- Raspberry Pi OS and compatible Debian systems use the smaller
  `Brewfile.raspberry-pi` plus apt-based bootstrap.

## Repository contents

- `sh/setup` — install, update, platform bootstrap, and workbench orchestration.
- `sh/helpers.sh`, `sh/exports.sh`, `sh/aliases.sh` — interactive shell setup.
- `config/wezterm`, `config/hammerspoon`, `config/gnupg`,
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
- Singularity uses its official remote MCP configuration from
  `agent-workbench`.
- The shell alias `nvimconfig` opens the configuration installed by
  `nvim-workbench`.

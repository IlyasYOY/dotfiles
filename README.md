# Dotfiles

Personal dotfiles and workstation bootstrap for my day-to-day development
setup.

It is centered on Neovim, zsh, tmux, terminal tooling, and language support
for Go, Java, Lua, Python, and SQL.

> [!WARNING]
> This is a personal, opinionated setup that changes often. The bootstrap
> scripts assume my project layout under `~/Projects/IlyasYOY`, clone a few
> personal repositories, and install macOS-specific tooling. Review the
> scripts before running them.

## Platform support

This repository is primarily built for macOS. The editor and shell
configuration can still be reused elsewhere, but the automation in
`sh/setup/*.sh` is built around Homebrew, `mas`, Hammerspoon, Amethyst, and
other macOS tools.

## Repository contents

- `config/nvim` — full Neovim configuration with `vim.pack`, LSP/DAP,
  Treesitter, snippets, `fzf-lua`, Git tooling, database tooling, and Copilot
  integration.
- `config/nvim-minimal` — minimal Neovim configuration for reproducing issues.
- `sh` — shell helpers, aliases, exports, and setup/update scripts.
- `config/wezterm`, `config/hammerspoon`, `config/gnupg`,
  `config/.tmux.conf`, `config/.amethyst.yml`,
  `config/.vimrc` — terminal, desktop, and core CLI configuration tracked in
  the repository.
- `config/copilot` — checked-in Copilot instructions and agent
  configuration.
- `bin` — small personal utilities and executable helpers.

## Prerequisites

Before running the bootstrap script, make sure you have:

- macOS
- Homebrew
- Git
- `curl`
- `zsh`

## Installation

```bash
mkdir -pv ~/Projects/IlyasYOY
cd ~/Projects/IlyasYOY
git clone git@github.com:IlyasYOY/dotfiles.git dotfiles
cd dotfiles
make install
```

`make install` runs `sh/setup/install.sh`. It creates the expected project
directories, links the core configs into `~/.config` and `$HOME`, appends
shell startup lines to `~/.zshrc`, configures Git defaults, installs version
managers (`SDKMAN`, `fnm`, `gvm`), sets up tmux plugins, bootstraps macOS
packages/apps, and links Copilot config if `~/.copilot` already exists.

Main links created by the installer:

- `config/nvim` -> `~/.config/nvim`
- `config/nvim-minimal` -> `~/.config/nvim-minimal`
- `config/wezterm` -> `~/.config/wezterm`
- `config/hammerspoon` -> `~/.hammerspoon`
- `config/gnupg/gpg-agent.conf` -> `~/.gnupg/gpg-agent.conf`
- `config/.gitignore-global` -> `~/.config/git/ignore`
- `config/.golangci.yml` -> `~/.golangci.yml`
- `config/.tmux.conf` -> `~/.tmux.conf`
- `config/.vimrc` -> `~/.vimrc`
- `config/.amethyst.yml` -> `~/.amethyst.yml`

## Maintenance

```bash
make update
```

`make update` runs `sh/setup/update.sh`. On macOS it updates Homebrew formulae
and casks, App Store apps, tracked local repositories, and tmux plugins.

## Local checks

```bash
make check
make check-lua
make check-shell
make format-lua
```

- `make check` runs the first-pass validation for Lua and shell files.
- `make check-lua` runs the Lua lint and formatting checks.
- `make check-shell` runs `shellcheck` for shell scripts and shell fragments.
- `make format-lua` formats Lua files with `stylua`.

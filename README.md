# Dotfiles

Personal dotfiles and workstation bootstrap for my day-to-day development
setup.

It is centered on Neovim, zsh, tmux, terminal tooling, and language support
for Go, Java, Lua, Python, and SQL.

> [!WARNING]
> This is a personal, opinionated setup that changes often. The bootstrap
> scripts assume my project layout under `~/Projects/IlyasYOY`, clone a few
> personal repositories, and still include macOS-specific tooling. Raspberry Pi
> support is intentionally a smaller first-pass bootstrap. Review the scripts
> before running them.

## Platform support

This repository is primarily built for macOS, but `sh/setup/install.sh` now has
an initial Raspberry Pi path as well. The macOS flow still includes Homebrew,
`mas`, Hammerspoon, Amethyst, and other desktop tooling; the Raspberry Pi flow
focuses on system bootstrap and a smaller CLI/dev tool base.

## Repository contents

- `config/nvim` — full Neovim configuration with eager `vim.pack` plugin
  registration in `lua/ilyasyoy/pack.lua`, plus LSP/DAP, Treesitter, snippets,
  `fzf-lua`, Git tooling, and database tooling.
- `config/nvim-minimal` — minimal Neovim configuration for reproducing issues.
- `sh` — shell helpers, aliases, exports, and setup/update scripts.
- `config/wezterm`, `config/hammerspoon`, `config/gnupg`,
  `config/.tmux.conf`, `config/.amethyst.yml`,
  `config/.vimrc` — terminal, desktop, and core CLI configuration tracked in
  the repository.
- `config/opencode` — checked-in OpenCode instructions and agent
  configuration.
- `bin` — small personal utilities and executable helpers.

## Prerequisites

Before running the bootstrap script, make sure you have:

- macOS or Raspberry Pi OS / Debian-based Linux on a Raspberry Pi
- Git
- `curl`
- `zsh` on macOS or `bash` on Raspberry Pi

On macOS, Homebrew is still expected to be available before running the
bootstrap script.

On Raspberry Pi, Homebrew is bootstrapped by the installer itself, but `git`,
`curl`, `sudo`, and a Debian-compatible `apt` environment are still assumed.

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
shell startup lines to the active shell rc file (`~/.zshrc` on macOS,
`~/.bashrc` on Raspberry Pi), configures Git defaults, installs version
managers (`SDKMAN`, `fnm`, `gvm`), sets up tmux plugins, installs OpenCode
with Homebrew, and links OpenCode config into `~/.config/opencode`.

On macOS, the installer still bootstraps the full Homebrew/App Store setup.

On Raspberry Pi, the installer now:

- runs `apt-get update` and `apt-get upgrade -y`
- installs Homebrew and toolchain prerequisites with `apt` (including `bison`
  for `gvm`)
- configures the official `sing-box` apt repository and installs `sing-box`
- installs Homebrew on Linux
- installs `gh` and `anomalyco/tap/opencode` with Homebrew
- installs a minimal first-pass core CLI/dev set with Homebrew:
  `fzf`, `luacheck`, `ripgrep`, `tree-sitter-cli`, `tmux`, `neovim`,
  `python`, `rust`, and `wget`, plus `go` and `pass`
- installs Node.js and `npm` with `fnm` when they are not already available
- writes shell startup config to `~/.bashrc` instead of `~/.zshrc`

`luacheck` is installed by the bootstrap scripts instead of Mason. Mason's
LuaRocks package currently resolves against Lua 5.5 on newer systems, which
breaks `luacheck` dependency resolution upstream, so the Neovim config no
longer asks Mason to manage that tool.

Main links created by the installer:

- `config/nvim` -> `~/.config/nvim`
- `config/nvim-minimal` -> `~/.config/nvim-minimal`
- `config/gnupg/gpg-agent.conf` -> `~/.gnupg/gpg-agent.conf`
- `config/.gitignore-global` -> `~/.config/git/ignore`
- `config/.golangci.yml` -> `~/.golangci.yml`
- `config/opencode/AGENTS.md` -> `~/.config/opencode/AGENTS.md`
- `config/opencode/agents` -> `~/.config/opencode/agents`
- `config/.tmux.conf` -> `~/.tmux.conf`
- `config/.vimrc` -> `~/.vimrc`

macOS-only links created by the installer:

- `config/wezterm` -> `~/.config/wezterm`
- `config/hammerspoon` -> `~/.hammerspoon`
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

# Dotfiles

Personal dotfiles and workstation bootstrap for my day-to-day development
setup.

It is centered on Neovim, shell tooling, tmux, terminal apps, Codex
configuration, and language support for Go, Java, Lua, Python, and SQL.

> [!WARNING]
> This is a personal, opinionated setup that changes often. The bootstrap
> scripts assume my project layout under `~/Projects/IlyasYOY`, clone a few
> personal repositories, manage shell startup files, and still include
> macOS-specific desktop tooling. Review the scripts before running them on a
> machine you care about.

## Platform support

This repository is primarily built for macOS, with a smaller Raspberry Pi
bootstrap path for Raspberry Pi OS or Debian-based Linux on Raspberry Pi
hardware.

- macOS installs Homebrew formulae, casks, and App Store apps from
  `Brewfile.mac`, `Brewfile.mac.cask`, and `Brewfile.mac.mas`, then links
  desktop configuration such as WezTerm, Hammerspoon, and Amethyst.
- Raspberry Pi runs apt-based system bootstrap, configures the `sing-box`
  repository, installs Linuxbrew when needed, and installs a smaller CLI/dev
  tool set from `Brewfile.raspberry-pi`.

## Repository contents

- `config/nvim` — full Neovim configuration with eager `vim.pack` registration,
  Treesitter, LSP/DAP, snippets, `fzf-lua`, Git tooling, and database helpers.
- `config/nvim-minimal` — minimal Neovim setup for reproducing issues.
- `sh` — shared shell helpers plus install and update entrypoints.
- `config/wezterm`, `config/alacritty`, `config/hammerspoon`,
  `config/gnupg`, `config/.tmux.conf`, `config/.amethyst.yml`,
  `config/.vimrc` — terminal, desktop, and CLI configuration tracked in the
  repo.
- `config/codex` — checked-in Codex instructions and repo-managed custom
  skills.
- `.agents/skills` — repository-local Codex skills used when working in this
  checkout.
- `Brewfile.mac`, `Brewfile.mac.cask`, `Brewfile.mac.mas`,
  `Brewfile.raspberry-pi` — package manifests used by the bootstrap scripts.
- `bin` — small personal utilities and executable helpers.

## Prerequisites

Before running the bootstrap flow, make sure you have:

- macOS or Raspberry Pi OS / Debian-based Linux on a Raspberry Pi
- Git
- `curl`
- `zsh` on macOS or `bash` on Raspberry Pi

On macOS, Homebrew is expected to be available before running `make install`.

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

`make install` runs `sh/setup/install.sh`. The install flow:

1. Creates the expected project directories under `~/Projects`.
2. Installs platform dependencies from the relevant Brewfiles.
3. Clones notes and a small set of personal repositories into
   `~/Projects/IlyasYOY`.
4. Links tracked config into `~/.config` and `$HOME`.
5. Appends shell startup lines to the active rc file: `~/.zshrc` on macOS and
   `~/.bashrc` on Raspberry Pi.
6. Configures Git defaults.
7. Installs and configures `SDKMAN`, `gvm`, and `fnm`.
8. Sets up tmux TPM, clones the password store, and links Codex instructions
   plus repo-managed skills into `~/.codex`.

On macOS, the installer uses:

- `Brewfile.mac` for formulae
- `Brewfile.mac.cask` for casks, including `codex`
- `Brewfile.mac.mas` for App Store installs

On Raspberry Pi, the installer:

- runs `apt-get update` and `apt-get upgrade -y`
- installs Homebrew and toolchain prerequisites with `apt` (including `bison`
  for `gvm`)
- configures the official `sing-box` apt repository and installs `sing-box`
- installs Linuxbrew if it is not already present
- installs Homebrew-managed dependencies from `Brewfile.raspberry-pi`
- installs Node.js and `npm` with `fnm` when they are not already available
- writes shell startup config to `~/.bashrc` instead of `~/.zshrc`

The Brewfile-backed install steps use:

```bash
brew bundle install --file <brewfile> --jobs auto --no-upgrade
```

That keeps `make install` focused on missing dependencies instead of upgrading
everything already on the machine.

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
- `config/codex/AGENTS.md` -> `~/.codex/AGENTS.md`
- `config/codex/skills/superpowers` -> `~/.codex/skills/superpowers`
- `config/.tmux.conf` -> `~/.tmux.conf`
- `config/.vimrc` -> `~/.vimrc`

macOS-only links created by the installer:

- `config/wezterm` -> `~/.config/wezterm`
- `config/hammerspoon` -> `~/.hammerspoon`
- `config/.amethyst.yml` -> `~/.amethyst.yml`

## If You Want To Use This Config Yourself

This repo can be a good base, but several parts of it are still wired to my
personal machines, paths, repositories, and services. Review these before you
try to use it unchanged.

### Change these first

- Project layout: the setup scripts assume `~/Projects/IlyasYOY` plus
  `~/Projects/Work`, with notes living in `~/Projects/IlyasYOY/notes-wiki` and
  `~/Projects/IlyasYOY/Legacy-Notes`. If you use a different layout, update the
  path constants in `sh/setup/helpers.sh`.
- Personal repositories: `sh/setup/install.sh` and `sh/setup/update.sh` clone
  and update personal repositories such as `notes-wiki`, `obs.nvim`,
  `theme.nvim`, `git-link.nvim`, `monotask`, and `password-store`. Remove,
  replace, or comment those entries if you do not own those repositories.
- Secrets and external services: `sh/helpers.sh` defines `codex-time-manager`,
  which expects `pass singularity/token/full`, a local Singularity MCP checkout
  at `~/Projects/IlyasYOY/singularity-mcp-server-2.1.1`, and Google Calendar
  integration inside Codex. If you do not use that exact setup, retarget or
  remove those helpers.
- Java setup: Neovim Java support looks for SDKMAN-managed JDKs in
  `~/.sdkman/candidates/java/`. The current helper supports JDK `8`, `11`,
  `17`, `21`, `23`, and `25`, and prefers `21` when available. If none of
  those are installed, `jdtls` is skipped.

### Optional personal integrations

- Notes workflow: `config/nvim/after/plugin/obs.lua` points `obs.nvim` at
  `~/Projects/IlyasYOY/notes-wiki`, and shell aliases/helpers also assume that
  notes location. Change those paths if you use a different vault, or disable
  the integration.
- Local plugin development: `config/nvim/lua/ilyasyoy/pack.lua` prefers local
  checkouts under `~/Projects/IlyasYOY/<plugin>` before falling back to GitHub.
  That is convenient for my plugin workflow, but you may want to remove those
  local overrides.
- Shell defaults: `sh/exports.sh` sets macOS-specific Colima and Docker socket
  environment variables. If you do not use Colima, review or remove those
  exports.
- Packages and apps: the Brewfiles and `mas` entries reflect my machine, not a
  minimal universal setup. Trim them to the tools and desktop apps you actually
  want.

## Maintenance

```bash
make update
```

`make update` runs `sh/setup/update.sh`.

- On macOS it updates Homebrew itself, formulae, casks, App Store apps, tracked
  local repositories, and tmux plugins.
- On Raspberry Pi it updates apt packages, Homebrew, Homebrew packages, tracked
  local repositories, and tmux plugins.

## Local checks

```bash
make check
make check-lua
make check-shell
make format-lua
```

- `make check` runs the first-pass validation for Lua and shell files and is
  the same check target used by CI.
- `make check-lua` runs the Lua lint and formatting checks.
- `make check-shell` runs `shellcheck` for shell scripts and shell fragments.
- `make format-lua` formats Lua files with `stylua`.

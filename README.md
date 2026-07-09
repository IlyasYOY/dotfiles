# Dotfiles

Personal dotfiles and workstation bootstrap for my day-to-day development
setup.

It is centered on Neovim, shell tooling, tmux, terminal apps, Codex and
OpenCode configuration, and language support for Go, Java, Lua, Python, and
SQL.

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
- `config/wezterm`, `config/hammerspoon`, `config/gnupg`,
  `config/.tmux.conf`, `config/.amethyst.yml`, `config/.vimrc` — terminal,
  desktop, and CLI configuration tracked in the repo.
- `config/agent/skills` — shared portable skills linked into both Codex and
  OpenCode. Any immediate child directory with `SKILL.md` is installed.
- `config/codex` — Codex instructions, rules, and Codex-only skills that read
  local Codex session state.
- `config/opencode` — checked-in OpenCode instructions, global config, and
  command prompts that load the shared portable skill set.
- `.agents/skills` — repository-local agent skills used when working in this
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
8. Sets up tmux TPM, clones the password store, and links Codex and OpenCode
   instructions, config, commands, rules, and skills into `~/.codex` and
   `~/.config/opencode`.

On macOS, the installer uses:

- `Brewfile.mac` for formulae, including the standard Homebrew `opencode`
  formula
- `Brewfile.mac.cask` for casks, including the Codex desktop casks
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

Setup debug logs are hidden by default. To include them, run:

```bash
make install VERBOSE=1
```

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
- `config/codex/rules/default.rules` -> `~/.codex/rules/default.rules`
- shared portable skills from `config/agent/skills/<skill>/SKILL.md` ->
  `~/.codex/skills/IlyasYOY/<skill>` and
  `~/.config/opencode/skills/<skill>`
- Codex-only skills from `config/codex/skills/<skill>/SKILL.md` ->
  `~/.codex/skills/IlyasYOY/<skill>`
- OpenCode-only skills from `config/opencode/skills/<skill>/SKILL.md` ->
  `~/.config/opencode/skills/<skill>`
- `config/opencode/AGENTS.md` -> `~/.config/opencode/AGENTS.md`
- `config/opencode/opencode.json` -> `~/.config/opencode/opencode.json`
- `config/opencode/commands` -> `~/.config/opencode/commands`
- `config/.tmux.conf` -> `~/.tmux.conf`
- `config/.vimrc` -> `~/.vimrc`

Codex uses `config/codex/AGENTS.md`, `config/codex/rules/default.rules`, and
managed TOML blocks in `~/.codex/config.toml`. Shared portable skills such as
`caveman`, `git-commit`, and `hammerspoon` are linked from
`config/agent/skills`. Codex-only session-history skills stay under
`config/codex/skills` because they read `~/.codex/state_5.sqlite` and rollout
files. Setup discovers installable skills from immediate child directories that
contain `SKILL.md`.

OpenCode uses `config/opencode/opencode.json` as a global config with cautious
permissions for file edits, shell commands, web fetch/search, and skills. The
OpenCode skill links include shared portable skills from `config/agent/skills`
and OpenCode-only skills from `config/opencode/skills`, including separate
OpenCode implementations of session-history skills such as `ai-session-coach`
and `session-hardener`. Codex session-history skill directories are not
installed into OpenCode.

If the OpenCode config path is missing, the installer links the repo default.
If a strict JSON object already exists there, the installer writes a timestamped
backup and fills only missing defaults, preserving all existing user settings.
JSONC, invalid JSON, non-object JSON, and symlinks to other targets are left
unchanged with a warning.

The installer manages Codex config links and repo-owned skill links, but it
does not delete Codex sessions, auth, app state, plugins, memories, or OpenCode
state.

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
  `~/Projects/Work`, with notes living in `~/Projects/kb-store`. If you use a
  different layout, update the path constants in `sh/setup/helpers.sh`.
- Notes: `sh/setup/install.sh` initializes `~/Projects/kb-store` as a local git
  repository when it is missing.
- Personal repositories: `sh/setup/install.sh` and `sh/setup/update.sh` clone
  and update personal repositories such as `obs.nvim`, `theme.nvim`,
  `git-link.nvim`, `monotask`, and `password-store`. Remove, replace, or
  comment those entries if you do not own those repositories.
- Secrets and external services: the bootstrap clones a personal password-store
  repository and shell helpers assume that store is available. If you do not use
  that exact setup, remove or replace those entries.
- Java setup: Neovim Java support looks for SDKMAN-managed JDKs in
  `~/.sdkman/candidates/java/`. The current helper supports JDK `8`, `11`,
  `17`, `21`, `23`, and `25`, and prefers `21` when available. If none of
  those are installed, `jdtls` is skipped.

### Optional personal integrations

- Notes workflow: `config/nvim/after/plugin/obs.lua` points `obs.nvim` at
  `~/Projects/kb-store`, and shell aliases/helpers also assume that
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

Update debug logs are hidden by default. To include them, run:

```bash
make update VERBOSE=1
```

## Local checks

```bash
make check
make check-lua
make check-shell
make check-python
make format-lua
```

- `make check` runs the first-pass validation for Lua, shell, and Python skill
  files and is the same check target used by CI.
- `make check-lua` runs the Lua lint and formatting checks.
- `make check-shell` runs `shellcheck` for shell scripts and shell fragments.
- `make check-python` runs the AI session coach's standard-library tests.
- `make format-lua` formats Lua files with `stylua`.

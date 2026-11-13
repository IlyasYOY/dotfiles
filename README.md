# Dotfiles

Personal workstation bootstrap and the top-level orchestrator for my development
environment.

This repository owns operating-system packages, shell startup, terminal and
desktop configuration, language version managers, and coordination of
[`nvim-workbench`](https://github.com/IlyasYOY/nvim-workbench) for Neovim
configuration and personal plugin development. That workbench follows its
upstream `main` branch and owns its installation, dependency updates, and checks.

Start agent sessions in the Home Repo at `~/Projects/IlyasYOY`. This cockpit
owns shared agent instructions, skills, docs, and project routing. Personal
agent material is used there directly, without a global installation.
The retired `agent-workbench` repository is retained as an archive; its
installation instructions are historical and must not be used for this setup.

> [!WARNING]
> This is a personal, opinionated setup. The bootstrap assumes my project
> layout under `~/Projects/IlyasYOY`, manages shell startup files, clones
> personal repositories, and contains macOS-specific setup.

## Platform support

- macOS packages come from `Brewfile.mac` and `Brewfile.mac.cask`; desktop
  configuration includes WezTerm, Hammerspoon, and Amethyst.

`make install` and `make update` support macOS only and exit before making
changes on other operating systems. Managed shell startup uses Zsh (`~/.zshrc`).

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
mkdir -pv ~/Projects/IlyasYOY/0_projects
cd ~/Projects/IlyasYOY/0_projects
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
6. clones and calls `make install` in `nvim-workbench`.

On macOS, installation discovers Homebrew on PATH or under `/opt/homebrew`
and `/usr/local`, bootstraps it if necessary, and loads its shell environment
before installing packages. Installer downloads must complete successfully
and be nonempty before execution; SDKMAN, GVM, and Oh My Zsh must provide their
initialization files before installation is considered successful. Incomplete
existing installations are reported and left intact for manual repair.

Oh My Zsh is installed before managed shell configuration and preserves an
existing `.zshrc`, including symlinks. Repeated installation also installs any
missing tmux plugins, even when TPM already exists.

GnuPG setup renders `~/.config/dotfiles/gpg-agent.conf` and links it from
`~/.gnupg/gpg-agent.conf`. macOS resolves Touch ID pinentry from Homebrew's
formula prefix and keeps zero cache TTLs and the DisableKeychain preference.
The previous dotfiles-owned symlink
is saved under `~/.gnupg/dotfiles-backup.*` when migrated. Unknown GnuPG files
and symlinks are left unchanged with a warning. Only generated files bearing
the dotfiles ownership marker are refreshed by subsequent installs or updates.

The install also configures Worktrunk's shell integration. The update flow
refreshes that integration after package upgrades so its shell wrapper stays
compatible with the installed Worktrunk version.

The workbench installation can be run independently:

```bash
make install-workbenches
```

The default checkout is `~/Projects/IlyasYOY/0_projects/nvim-workbench`.
Override it with `ILYASYOY_NVIM_WORKBENCH_DIR`. The existing
`install-workbenches` and `update-workbenches` target names now manage only
Neovim; the former agent-workbench override is ignored.

`nvim-workbench` installs `~/.config/nvim`. The former
`~/.config/nvim-minimal` setup is no longer managed.

## Updating

```bash
make update
```

The main update first pulls the executing dotfiles checkout, then reconciles
the current platform Brewfiles and upgrades installed packages. New formulae
and casks are installed in the same run; undeclared packages are not removed.
It also refreshes GnuPG configuration, tracked personal repositories,
`nvim-workbench`, missing and installed tmux plugins, and Go tools. The workbench
follows its configured upstream branch and updates the dependencies it owns.

Required package, installer, plugin, and Git failures return a failing exit
status and stop dependent work. Parallel Git batches finish all workers before
returning failure and retain logs for diagnosis. Password-store operations are
explicitly optional. Missing unrelated personal checkouts are skipped during
updates; the `t-invest-mcp` checkout must exist and update successfully before
its tools can be built. Dotfiles refresh failures are always fatal.

To update only the Neovim workbench:

```bash
make update-workbenches
```

## Codex launch modes

Use these shell aliases to choose whether Apps and Plugins are available for
a Codex CLI invocation:

```bash
codex-core                   # explicitly disable Apps and Plugins
codex-extra                  # explicitly enable Apps and Plugins
codex-core resume --last      # resume with both disabled
codex-extra "Review my notes" # pass a prompt with both enabled
```

Both aliases forward additional arguments and preserve Codex's exit status.
The flags apply only to that CLI invocation; they do not change project
configuration or Desktop settings. Enabling Apps and Plugins allows already
configured integrations to be used; it does not install or connect them.
Open a new shell or run `source "$ILYASYOY_DOTFILES_DIR/sh/aliases.sh"` to load
the aliases in an existing shell.

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
remaining Lua and shell configuration plus the setup and workbench orchestration
contracts. Setup tests exercise failures, repeat installations, file preservation,
Bash/Zsh startup, and the `make install` / `make update` entrypoints using
temporary homes and fake external commands; they do not install packages or
modify live workstation configuration. Bash and Zsh are required to run these
checks. Run `make check` inside each workbench for its own static and runtime
checks.

## Personal integration points

- Project roots default to `~/Projects/IlyasYOY/0_projects` and `~/Projects/Work`.
- `GIT_PARALLEL_JOBS` controls parallel checkout updates.
- T-Invest MCP is built from `~/Projects/IlyasYOY/0_projects/t-invest-mcp`; token values
  remain environment variables and are never stored here.
- The shell alias `nvimconfig` opens the configuration installed by
  `nvim-workbench`.

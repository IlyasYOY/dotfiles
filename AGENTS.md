# AGENTS.md

This file contains instructions for agentic coding assistants operating in this repository. It provides build/lint/test commands and code style guidelines to ensure consistent development practices.

## Agent Operating Rules

- Do not make commits unless the user explicitly asks for one.
- Explain what changed, why it changed, and how it was verified.
- Preserve user changes already present in the worktree. If unrelated files are
  dirty, leave them alone.

## Repository Overview

This is a personal dotfiles and workstation bootstrap repository for day-to-day
development. It includes Neovim and shell configuration, bootstrap/update
scripts, Homebrew manifests, OpenCode instructions and skills, and terminal or
desktop configuration for macOS plus a smaller Raspberry Pi bootstrap path.

## Build/Lint/Test Commands

### Lua

```bash
# Run all first-pass CI checks (same command as CI)
make check
```

`make check` runs Lua, shell, and Python checks.

```bash
# Lint Lua files without auto-formatting
make check-lua
luacheck $(git ls-files -- '*.lua')
stylua --check $(git ls-files -- '*.lua')

# Format Lua files
make format-lua
stylua $(git ls-files -- '*.lua')

# Format specific file
stylua config/nvim/lua/ilyasyoy/init.lua
```

CI runs Lua 5.4, installs `luacheck` with LuaRocks, installs
`shellcheck`, and pins StyLua to `v2.4.0` before running `make check`.
Python checks use the system `python3` available on the CI runner.

### Shell Scripts

```bash
# Check shell fragments, setup scripts, and shell-shebang files in bin/
make check-shell

# Fragments without shebangs are linted as bash
shellcheck -s bash sh/aliases.sh sh/exports.sh

# Run setup flows directly
bash sh/setup/install.sh
bash sh/setup/update.sh

# Top-level helpers
make install
make update

# Show setup/update debug logs
make install VERBOSE=1
make update VERBOSE=1
```

### Python

```bash
# Compile Python utilities and run Python unit tests
make check-python

# Run the Python tests directly
python3 -m unittest discover -s tests -p 'test_*.py'

# Run a focused test module
python3 -m unittest tests.test_vless_switch
```

## Code Style Guidelines

### General Principles

- Follow language-specific conventions and tools
- Use meaningful names for variables, functions, and files
- Add comments for complex logic
- Keep functions/methods focused on single responsibilities
- Handle errors appropriately in each language

### Lua (Neovim Configuration)
- Use `stylua` with configuration from `stylua.toml`:
  - 4 spaces indentation
  - 80 column width
  - Unix line endings
  - Double quotes preferred
  - Omit call parentheses where StyLua allows it
- Use `luacheck` for linting
- Follow Neovim Lua conventions
- Use `vim.keymap.set()` for key mappings
- Use descriptive keymap descriptions
- Handle Vim options properly
- Use local variables when possible
- Keep shared `vim.pack` specs and eager registration in `config/nvim/lua/ilyasyoy/pack.lua`
- Keep `config/nvim/nvim-pack-lock.json` and `config/nvim/ts-pack-lock.json`
  under version control when plugin or Treesitter lock state changes
- Keep plugin-level configuration in `config/nvim/after/plugin/*.lua`,
  including LSP, DAP, Fugitive, Dispatch, FZF, Treesitter, and Obsidian setup
- Keep `config/nvim/after/ftplugin/*.lua` focused on buffer-local options,
  filetype-specific mappings, and commands
- Keep plugin loading eager unless a task explicitly asks to reintroduce lazy loading
- `pack.lua` may prefer local plugin checkouts under
  `~/Projects/IlyasYOY/<plugin>` before falling back to GitHub; preserve that
  workflow unless the task says otherwise

### Shell Scripts

- Use `#!/usr/bin/env bash` for executable bash scripts
- Set `set -euo pipefail` in executable setup scripts and new standalone
  scripts when it will not break sourced interactive usage
- Use descriptive function names
- Quote variables properly
- Use `local` for function variables
- Add comments for complex operations
- Use consistent error handling
- Keep the files sourced from the active shell rc file (`~/.zshrc` on macOS,
  `~/.bashrc` on Raspberry Pi) — `sh/helpers.sh`, `sh/exports.sh`, and
  `sh/aliases.sh` — safe for interactive shell startup
- Treat `sh/aliases.sh` and `sh/exports.sh` as shell fragments linted with
  `shellcheck -s bash`; `sh/helpers.sh`, `sh/setup/*.sh`, and shell-shebang
  files in `bin/` are linted as scripts by `make check-shell`
- Put executable setup flows under `sh/setup/`
- Keep bootstrap helpers and platform-specific setup behavior in
  `sh/setup/helpers.sh`, `sh/setup/mac.sh`, and `sh/setup/raspberry-pi.sh`
- Keep clone/update parallelism in the shared setup helpers and respect
  `GIT_PARALLEL_JOBS` when changing personal repository bootstrap behavior
- Keep macOS GnuPG Touch ID pinentry behavior coordinated across
  `Brewfile.mac`, `config/gnupg/gpg-agent.conf`, and `sh/setup/mac.sh`

### Python

- Follow PEP 8 style guide
- Use type hints where beneficial
- Write docstrings for functions and classes
- Handle exceptions appropriately
- Use virtual environments
- Keep imports organized (standard library, third-party, local)
- Keep Python CLI utilities in `bin/` importable without side effects so
  `tests/test_*.py` can load and exercise them directly
- Prefer standard-library dependencies for personal utility scripts unless
  the bootstrap manifests already install the required tool

## File Organization

### Directory Structure

- `config/` - Application configurations
- `Brewfile.mac`, `Brewfile.mac.cask`, `Brewfile.mac.mas`, `Brewfile.raspberry-pi` - Platform package manifests used by bootstrap flows
- `sh/` - Shell scripts and utilities
- `sh/setup/` - Installation and update scripts (install.sh, update.sh, mac.sh, raspberry-pi.sh)
- `bin/` - Executable personal utilities, including Python CLIs such as
  `vless-switch` and `ilyasyoy-ffmpeg-parse-chapters`
- `tests/` - Small reproducible tests and experiments that support repo
  changes, including Python unit tests and focused Lua repro scripts
- `config/nvim/` - Neovim configuration
- `config/nvim/nvim-pack-lock.json`, `config/nvim/ts-pack-lock.json` - Lock
  files for `vim.pack` plugins and Treesitter parsers
- `config/nvim-minimal/` - Minimal Neovim configuration for reproducing issues
- `config/nvim/lua/ilyasyoy/pack.lua` - Shared `vim.pack` specs and eager plugin registration
- `config/nvim/lua/ilyasyoy/functions/` - Shared Neovim Lua helpers for core
  mappings, Java, password-store, tests, and Treesitter behavior
- `config/nvim/after/ftplugin/` - Language-specific Neovim configs
- `config/nvim/after/plugin/` - Per-plugin Neovim configs loaded after plugins become available
- `config/nvim/after/queries/` - Treesitter query overrides and injections
- `config/nvim/snippets/` - LuaSnip snippets (gitcommit, go, java, lua, markdown)
- `config/nvim/spell/` - Checked-in custom spell files used by Neovim
- `config/wezterm/`, `config/hammerspoon/`, `config/gnupg/`,
  `config/.tmux.conf`, `config/.vimrc`, `config/.amethyst.yml` - Terminal,
  desktop, GnuPG, tmux, and Vim configuration
- `config/.gitignore-global`, `config/.golangci.yml` - Global Git ignore and
  Go lint configuration linked by setup
- `.agents/skills/` - Repository-local agent skills such as
  `dotfiles-luasnip/SKILL.md`
- `.github/workflows/` - CI workflows such as `check.yml`
- `config/opencode/` - Checked-in OpenCode instructions, global config, and
  command prompts symlinked into `~/.config/opencode`

### File Naming

- Use lowercase with hyphens for shell scripts: `my-script.sh`
- Use lowercase with underscores for Python: `my_module.py`
- Follow language conventions for other files
- Use descriptive names that indicate purpose

### LuaSnip Snippets

When modifying or creating snippets in `config/nvim/snippets/*.lua`, use the
`$dotfiles-luasnip` repo-local skill in `.agents/skills/dotfiles-luasnip/`. It
covers the snippet structure, LuaSnip APIs, and the required workflow
(read -> append -> `luacheck` -> `stylua`).
Currently maintained snippet files are `gitcommit.lua`, `go.lua`, `java.lua`,
`lua.lua`, and `markdown.lua`.

## Git Workflow

### Commit Messages

- Use conventional commit format when possible
- Write clear, descriptive commit messages
- Keep commits focused on single changes
- Agents must not commit changes without explicit user approval

### Branching

- Use feature branches for new work
- Keep main/master branch stable
- Rebase before merging

## Testing Strategy

- Run `make check` before committing changes
- Use `make check-lua` or `make check-shell` for faster iteration on one area
- Use `make check-python` for Python utilities, especially changes to
  `bin/vless-switch`
- Keep changes compatible with the checks run by `.github/workflows/check.yml`
- Add targeted automated verification when introducing new executable logic or reproducible experiments
- For documentation-only changes, verify the edited instructions against the
  live repo files and scripts they describe

### Agent Experimentation

- When an agent wants to experiment to check a hypothesis, create a small function in the current project that implements the experiment and add an automated test that verifies the hypothesis. Do not run experiments in temporary directories (e.g., /tmp); experiments must live in the repository so they are reproducible and attachable to artifacts.
- The experiment code and its test must be added to the project's test suite so results are reviewable, reproducible, and easily reusable.
- Keep experiments small and well-documented. After review, either remove the experiment or refactor its logic into production code with proper tests and documentation.


## Security Considerations

- Never commit sensitive information (API keys, passwords)
- Use environment variables for secrets
- Follow principle of least privilege
- Validate inputs and handle errors securely
- Use secure coding practices for each language

## Performance Guidelines

- Profile code before optimizing
- Use appropriate data structures
- Avoid unnecessary computations
- Cache results when beneficial
- Consider memory usage in resource-constrained environments

## Documentation

- Update `README.md`, `AGENTS.md`, or agent instructions when workflows or layout change
- Document configuration options
- Add inline comments for complex logic

## Development Environment Setup

1. Clone repository: `git clone git@github.com:IlyasYOY/dotfiles.git`
2. Run installation: `make install`
3. Use the bootstrap scripts and Brewfiles in this repo as the source of truth
   for platform-specific setup
4. Update components later with `make update`
5. Verify setup by running `make check`

## OpenCode Configuration

- `sh/setup/install.sh` links `config/opencode/AGENTS.md`,
  `config/opencode/opencode.json`, and `config/opencode/commands` into
  `~/.config/opencode`
- OpenCode skill links are individual portable skills under
  `~/.config/opencode/skills/<skill>` from `config/opencode/skills/<skill>`
- Keep `config/opencode/opencode.json` valid JSON. OpenCode-specific command
  prompts live in `config/opencode/commands/*.md`.
- When installing OpenCode config, preserve existing user settings: symlink the
  repo default only when the destination is missing, and otherwise fill only
  missing defaults in strict JSON object configs after writing a backup.
- Future setup should not uninstall Codex or delete existing local Codex
  sessions, config, or app state.
- Use the local `git-commit` and `git-commit-split` skills only when the user
  asks for commit help; do not create commits without explicit approval.

## Tool Versions

- Go: Latest stable version with modules
- Node.js: LTS via fnm
- Python: 3.8+ with virtual environments
- Java: Latest LTS with SDKMAN
- Neovim: version with Lua support and built-in `vim.pack` support
- OpenCode: installed by the bootstrap flow and configured from
  `config/opencode/AGENTS.md`, `config/opencode/opencode.json`, and
  repo-managed skills

This document should be updated as coding standards evolve or new tools are adopted.

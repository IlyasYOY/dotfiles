# AGENTS.md

This file contains instructions for agentic coding assistants operating in this repository. It provides build/lint/test commands and code style guidelines to ensure consistent development practices.

## Repository Overview

This is a personal dotfiles repository containing configuration files for development tools and environments. It includes Neovim setup, shell configurations, and language-specific tooling for Go, Java, Python, Lua, and SQL.

## Build/Lint/Test Commands

### Lua

```bash
# Run all first-pass CI checks (same command as CI)
make check

# Lint Lua files without auto-formatting
make check-lua
luacheck .
stylua --check .

# Format Lua files
make format-lua
stylua .

# Format specific file
stylua config/nvim/lua/ilyasyoy/init.lua
```

### Shell Scripts

```bash
# Check shell fragments, setup scripts, and shell-shebang files in bin/
make check-shell

# Fragments without shebangs are linted as bash
shellcheck -s bash sh/aliases.sh sh/exports.sh

# Run setup scripts directly
bash sh/setup/install.sh
bash sh/setup/update.sh
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
- Keep plugin entrypoints in `config/nvim/plugin/*.lua`
- Keep shared `vim.pack` specs and helpers in `config/nvim/lua/ilyasyoy/pack.lua`
- Keep plugin configuration in `config/nvim/after/plugin/*.lua`
- Prefer existing `pack.on_load`, `pack.wrap`, and `pack.lazy_user_command` helpers for lazy-loaded plugins

### Shell Scripts

- Use `#!/usr/bin/env bash`
- Set `set -euo pipefail` for robustness
- Use descriptive function names
- Quote variables properly
- Use `local` for function variables
- Add comments for complex operations
- Use consistent error handling
- Keep the files sourced from `.zshrc`—`sh/helpers.sh`, `sh/exports.sh`, and `sh/aliases.sh`—safe for interactive shell startup
- Put executable setup flows under `sh/setup/`

### Python

- Follow PEP 8 style guide
- Use type hints where beneficial
- Write docstrings for functions and classes
- Handle exceptions appropriately
- Use virtual environments
- Keep imports organized (standard library, third-party, local)

## File Organization

### Directory Structure

- `config/` - Application configurations
- `sh/` - Shell scripts and utilities
- `sh/setup/` - Installation and update scripts (install.sh, update.sh, mac.sh)
- `bin/` - Executable binaries
- `config/nvim/` - Neovim configuration
- `config/nvim/plugin/` - `vim.pack` entrypoints and lazy-load stubs
- `config/nvim/lua/ilyasyoy/pack.lua` - Shared `vim.pack` specs and helper functions
- `config/nvim/after/ftplugin/` - Language-specific Neovim configs
- `config/nvim/after/plugin/` - Per-plugin Neovim configs loaded after plugins become available
- `config/nvim/after/queries/` - Treesitter query overrides and injections
- `config/nvim/snippets/` - LuaSnip snippets (go, java, lua, markdown)
- `.github/agents/` - Repository-local subagent docs such as `luasnip.md`
- `.github/workflows/` - CI workflows such as `check.yml`
- `config/copilot/copilot-instructions.md` - Copilot CLI instructions symlinked into `~/.copilot/`
- `config/copilot/agents/` - Copilot CLI agent definitions symlinked into `~/.copilot/agents`

### File Naming

- Use lowercase with hyphens for shell scripts: `my-script.sh`
- Use lowercase with underscores for Python: `my_module.py`
- Follow language conventions for other files
- Use descriptive names that indicate purpose

### LuaSnip Snippets

When modifying or creating snippets in `config/nvim/snippets/*.lua`, use the `luasnip` subagent defined in `.github/agents/luasnip.md`. It has specialized knowledge of the snippet structure, LuaSnip APIs, and the required workflow (read → append → luacheck → stylua).

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
- Keep changes compatible with the checks run by `.github/workflows/check.yml`
- Add targeted automated verification when introducing new executable logic or reproducible experiments

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

- Update `README.md`, `AGENTS.md`, or Copilot instructions when workflows or layout change
- Document configuration options
- Add inline comments for complex logic

## Development Environment Setup

1. Clone repository: `git clone git@github.com:IlyasYOY/dotfiles.git`
2. Run installation: `make install`
3. Update components: `make update`
4. Verify setup by checking linting passes

## Tool Versions

- Go: Latest stable version with modules
- Node.js: LTS via fnm
- Python: 3.8+ with virtual environments
- Java: Latest LTS with SDKMAN
- Neovim: version with Lua support and built-in `vim.pack` support

This document should be updated as coding standards evolve or new tools are adopted.

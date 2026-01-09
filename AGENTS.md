# AGENTS.md

This file contains instructions for agentic coding assistants operating in this repository. It provides build/lint/test commands and code style guidelines to ensure consistent development practices.

## Repository Overview

This is a personal dotfiles repository containing configuration files for development tools and environments. It includes Neovim setup, shell configurations, and language-specific tooling for Go, Java, Python, Lua, and SQL.

## Build/Lint/Test Commands

### Lua

```bash
# Lint Lua files
luacheck .

# Format Lua files
stylua .

# Format specific file
stylua config/nvim/lua/ilyasyoy/init.lua
```

### Shell Scripts

```bash
# Check shell scripts with shellcheck
shellcheck sh/*.sh bin/*

# Run shell script
bash sh/helpers.sh
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
- Use `luacheck` for linting
- Follow Neovim Lua conventions
- Use `vim.keymap.set()` for key mappings
- Use descriptive keymap descriptions
- Handle Vim options properly
- Use local variables when possible

### Shell Scripts

- Use `#!/usr/bin/env bash`
- Set `set -euo pipefail` for robustness
- Use descriptive function names
- Quote variables properly
- Use `local` for function variables
- Add comments for complex operations
- Use consistent error handling

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
- `bin/` - Executable binaries
- `config/nvim/` - Neovim configuration
- `config/aichat/roles/` - AI chat role definitions

### File Naming

- Use lowercase with hyphens for shell scripts: `my-script.sh`
- Use lowercase with underscores for Python: `my_module.py`
- Follow language conventions for other files
- Use descriptive names that indicate purpose

## Git Workflow

### Commit Messages

- Use conventional commit format when possible
- Write clear, descriptive commit messages
- Keep commits focused on single changes

### Branching

- Use feature branches for new work
- Keep main/master branch stable
- Rebase before merging

## Testing Strategy

- Write tests for new functionality
- Run tests before committing changes
- Ensure tests pass on all supported platforms

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

- Update README.md for significant changes
- Document configuration options
- Add inline comments for complex logic
- Maintain changelog for releases

## Development Environment Setup

1. Clone repository: `git clone git@github.com:IlyasYOY/dotfiles.git`
2. Run installation: `make install`
3. Update components: `make update`
4. Verify setup by checking linting passes

## Tool Versions

- Go: Latest stable version with modules
- Node.js: LTS via nvm
- Python: 3.8+ with virtual environments
- Java: Latest LTS with SDKMAN
- Neovim: 0.9+ with Lua support

This document should be updated as coding standards evolve or new tools are adopted.

# Dotfiles

My personal dotfiles and development environment configuration.
Built for productivity across multiple languages and tools.

## Disclaimer

> This configuration is constantly evolving. Use at your own
> risk. Always review changes before pulling updates.

## Features

- **Neovim IDE Setup**
  - LSP & DAP integration (Java, Go, Python, Lua, etc.)
  - Fuzzy finding (FZF-based)
  - Syntax highlighting (Treesitter)
  - Debugger integration (Java, Go, Python)
  - Obsidian note-taking integration
  - Custom snippets and mappings
- **Shell Environment**
  - Zsh configuration with Oh-My-Zsh
  - Tmux configuration with plugins
  - Git aliases and utilities
  - FZF integration
- **Language Support**
  - Java (JDTLS, Checkstyle, PMD)
  - Go (gopls, golangci-lint)
  - Python (pyright, pylint)
  - SQL (sqlfluff)
- **Tools Integration**
  - Wezterm & Alacritty terminal config
  - Hammerspoon for MacOS automation
  - Amethyst window manager setup
  - pass password manager.

## Installation

```bash
mkdir -pv ~/Projects/IlyasYOY/ 
cd ~/Projects/IlyasYOY/

# Clone repository
git clone git@github.com:IlyasYOY/dotfiles.git dotfiles
cd dotfiles

# Run install script
make install
```

## Structure

- `config` - configs for applications/utilities that I use.
  - `nvim-minimal` - minimal configuration so I can reproduce
    errors.
  - `nvim` - neovim configuration built by myself from zero.
- `sh` - shell scripts/aliases & etc.
- `bin` - binaries I might use from time to time.

## Maintenance

### Update all components

```bash
make update
```

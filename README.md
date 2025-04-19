# Dotfiles

My personal dotfiles and development environment configuration. Built for
productivity across multiple languages and tools.

## Features

- **Neovim IDE Setup**
  - LSP & DAP integration (Java, Go, Python, Lua, etc.)
  - FZF-based fuzzy finding
  - Treesitter syntax highlighting
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
  - Alacritty terminal config
  - Amethyst window manager setup
  - Obsidian note templates
  - Database client (vim-dadbod)

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

```text
.
├── bin # Binaries I use in my work & life.
├── config
│   ├── alacritty # configs for the terminal I use.
│   │   └── alacritty.toml
│   ├── checkstyle.xml
│   ├── eclipse-java-google-style.xml
│   ├── eclipse-my-java-google-style.xml
│   ├── nvim # nvim config.
│   ├── nvim-minimal # minimal nvim config I use to reproduce errors.
│   └── pmd.xml
├── helpers.sh # helpers I use in my maintanance scripts.
├── Makefile
├── README.md
├── setup-mac.sh # sets my mac up.
├── stylua.toml
└── update-mac.sh # updates my mac.
```

## Maintenance

### Update all components

```bash
make update
```

### Update Neovim plugins separately

```bash
nvim --headless "+Lazy! sync" +qa
```

## Disclaimer

> This configuration is constantly evolving. Use at your own risk. Always
> review changes before pulling updates.

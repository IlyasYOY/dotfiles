
from pyinfra import host
from pyinfra.facts.server import Home
from pyinfra.operations import brew, files, git, server

from common import (cwd_path, home_path_str, notes_path_str,
                    personal_projects_path_str, projects_path_str,
                    work_projects_path_str, zshrc_path_str)


def setup_mac_using_brew():
    """
    Install must-have packages I use almost every day.
    """

    brew.packages(
        packages=[
            "ast-grep",
            "bat",
            "cmake",
            "curl",
            "ffmpeg",
            "fzf",
            "gh",
            "go",
            "neovim",
            "ollama",
            "openjdk",
            "pmd",
            "pre-commit",
            "pyenv",
            "python@3.11",
            "python@3.12",
            "ripgrep",
            "rust",
            "sqlite",
            "tmux",
            "tree",
            "vim",
            "wget",
        ],
    )

    brew.casks(
        casks=[
            "alacritty",
            "amethyst",
            "betterdisplay",
            "discord",
            "google-chrome",
            "iina",
            "intellij-idea-ce",
            "karabiner-elements",
            "libreoffice",
            "netnewswire",
            "obsidian",
            "telegram",
            "transmission",
            "vial",
        ],
    )


def setup_basic_directories():
    """
    Here I craate basic directories I use every day.
    """
    for path in [
        projects_path_str,
        personal_projects_path_str,
        work_projects_path_str
    ]:
        files.directory(
            path=path,
            present=True,
        )


def setup_my_project():
    git.repo(
        src="git@github.com:IlyasYOY/obs.nvim.git",
        dest=f"{personal_projects_path_str}/obs.nvim",
    )
    git.repo(
        src="git@github.com:IlyasYOY/coredor.nvim.git",
        dest=f"{personal_projects_path_str}/coredor.nvim",
    )
    git.repo(
        src="git@github.com:IlyasYOY/git-link.nvim.git",
        dest=f"{personal_projects_path_str}/git-link.nvim",
    )


def setup_notes():
    """
    Download and install all my notes so I can use them as I work.
    """
    git.repo(
        src="git@github.com:IlyasYOY/Notes.git",
        dest=notes_path_str,
    )
    files.link(
        path=f"{home_path_str}/vimwiki",
        target=notes_path_str
    )


def setup_links_to_config_files():
    """
    Put all my configs in places they belong.
    """

    dot_config_path_str = f'{home_path_str}/.config'

    files.directory(path=dot_config_path_str,
                    present=True)

    files.link(path=f'{dot_config_path_str}/nvim',
               target=cwd_path / 'config/nvim')
    files.link(path=f'{dot_config_path_str}/nvim-minimal',
               target=cwd_path / 'config/nvim-minimal')
    files.link(path=f'{dot_config_path_str}/zentile',
               target=cwd_path / 'config/zentile')

    files.directory(path=f"{dot_config_path_str}/git",
                    present=True)
    files.link(path=f"{dot_config_path_str}/git/ignore",
               target=cwd_path / '.gitignore-global')
    files.link(path=f"{dot_config_path_str}/alacritty",
               target=cwd_path / 'config/alacritty')
    files.link(path=f"{home_path_str}/.golangci.yml",
               target=cwd_path / "config/.golangci.yml")
    files.link(path=f"{home_path_str}/.tmux.conf",
               target=cwd_path / ".tmux.conf")
    files.link(path=f"{home_path_str}/.ideavimrc",
               target=cwd_path / ".ideavimrc")
    files.link(path=f"{home_path_str}/.vimrc",
               target=cwd_path / ".vimrc")
    files.link(path=f"{home_path_str}/.amethyst.yml",
               target=cwd_path / ".amethyst.yml")


def setup_zshrc():
    """
    Put all my settin in .zshrc.
    """

    files.file(path=zshrc_path_str)

    files.line(path=zshrc_path_str,
               line='export EDITOR=nvim')
    files.line(path=zshrc_path_str,
               line='alias mnvim="NVIM_APPNAME=nvim-minimal nvim"')
    files.line(path=zshrc_path_str,
               line='alias nvims="nvim -S"')
    files.line(path=zshrc_path_str,
               line='alias vimconfig="vim ~/.vimrc"')
    files.line(path=zshrc_path_str,
               line='alias nvimconfig="nvim ~/.config/nvim/init.lua"')
    files.line(path=zshrc_path_str,
               line='alias mnvim="NVIM_APPNAME=nvim-minimal nvim"')
    files.line(path=zshrc_path_str,
               line='alias cdfzf=\'cd "$(find . -type d | fzf )"\'')
    files.line(path=zshrc_path_str,
               line='alias cdfzfgit=\'cd "$(find . -name .git -type d -prune | fzf)/.."\'')
    files.line(path=zshrc_path_str,
               line=f'export ILYASYOY_DOTFILES_DIR="{cwd_path}"')
    files.line(path=zshrc_path_str,
               line='export PATH="${ILYASYOY_DOTFILES_DIR}/bin:$PATH"')
    files.line(path=zshrc_path_str,
               line='alias ilyasyoy-dotfiles="cd ${ILYASYOY_DOTFILES_DIR}"')
    files.line(path=zshrc_path_str,
               line='alias ilyasyoy-notes="cd ~/vimwiki"')


def setup_sdkman():
    """
    Download SDKMAN to manage java.
    """
    server.shell(commands=['curl -s "https://get.sdkman.io" | bash'])


def setup_node_version_manager():
    """
    Install NVM to manage node & npm.
    """
    server.shell(commands=[
                 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'])
    nvm_source_script = ('export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"\n' +
                         '[ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh" # This loads nvm')
    files.block(path=zshrc_path_str,
                marker='## {mark} nvm ##',
                content=nvm_source_script,
                try_prevent_shell_expansion=True)
    server.shell(commands=[nvm_source_script + '&& nvm install --lts'])


def setup_ohmyzsh():
    """
    No comments here, everybody knows this.
    """
    server.shell(commands=[
                 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" | grep "already exists"'])


def setup_git_config():
    """
    Some basic git configuration
    """
    git.config(key='alias.st',
               value='status --short')
    git.config(key='alias.c',
               value='commit')
    git.config(key='alias.co',
               value='checkout')
    git.config(key='alias.lg',
               value='log --all --decorate --graph --oneline')
    git.config(key='diff.algorithm',
               value='histogram')


setup_mac_using_brew()
setup_basic_directories()
setup_notes()
setup_links_to_config_files()
setup_zshrc()
setup_sdkman()
setup_node_version_manager()
setup_ohmyzsh()
setup_git_config()

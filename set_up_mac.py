from pyinfra import host
from pyinfra.facts.server import Home
from pyinfra.operations import brew, files, git

# MacOS

brew.packages(
    packages=[
        "ast-grep",
        "bat",
        "fzf",
        "ripgrep",
        "curl",
        "wget",
        "ffmpeg",
        "cmake",
        "pre-commit",
        "tmux",
        "tree",

        "pmd",

        "pyenv",
        "python@3.12",
        "python@3.11",

        "vim",
        "neovim",


        "gh",
        "ollama",

        "go",
        "rust",
        "sqlite",
        "openjdk",
    ],
    latest=True,
)


brew.casks(
    casks=[
        "alacritty",
        "discord",
        "betterdisplay",
        "amethyst",
        "vial",
        "iina",
        "google-chrome",
        "intellij-idea-ce",
        "karabiner-elements",
        "libreoffice",
        "obsidian",
        "netnewswire",
        "telegram",
        "transmission",
    ],
    latest=True
)

brew.update()

brew.upgrade()

# Configs

# TODO: backup?

home = host.get_fact(Home)

files.directory(
    name="Ensure directory for Projects",
    path=f"{home}/Projects/",
    present=True,
)

files.directory(
    name="Ensure directory for personal projects",
    path=f"{home}/IlyasYOY",
    present=True,
)

files.directory(
    name="Ensure directory for work projects",
    path=f"{home}/Work",
    present=True,
)

files.directory(
    name="Ensure directory for Notes",
    path=f"{home}/IlyasYOY/Notes",
    present=True,
)

git.repo(
    name="Clone Notes",
    src="git@github.com:IlyasYOY/Notes.git",
    dest=f"{home}/IlyasYOY/Notes",
)

files.link(
    name="Create link from ~/vimwiki to cloned Notes",
    path=f"{home}/vimwiki",
    target=f"{home}/IlyasYOY/Notes"
)

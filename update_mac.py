from pyinfra.operations import brew, git, server

from common import home_path_str, notes_path_str, personal_projects_path_str


def update_mac_using_brew():
    """
    Update brew so I have all brand new deps every day.
    """
    brew.update()
    brew.upgrade()
    brew.cask_upgrade()


def update_nvim():
    """
    Here I update Lazy and MasonTools.
    Gladly nvim support command-line mode.
    """
    server.shell([
        'nvim --headless "+Lazy! sync" +qa'
    ])
    server.shell([
        'nvim --headless "+MasonToolsUpdateSync" +qa'
    ])


def update_local_repos():
    """
    Updates my local repos
    """
    git.repo(
        src="git@github.com:IlyasYOY/obs.nvim.git",
        dest=f"{personal_projects_path_str}/obs.nvim",
        pull=True,
    )
    git.repo(
        src="git@github.com:IlyasYOY/coredor.nvim.git",
        dest=f"{personal_projects_path_str}/coredor.nvim",
        pull=True,
    )
    git.repo(
        src="git@github.com:IlyasYOY/git-link.nvim.git",
        dest=f"{personal_projects_path_str}/git-link.nvim",
        pull=True,
    )
    git.repo(
        src="git@github.com:IlyasYOY/Notes.git",
        dest=notes_path_str,
        pull=True
    )
    git.repo(
        src="git@github.com:IlyasYOY/dotfiles.git",
        dest=f"{personal_projects_path_str}/dotfiles",
        pull=True,
    )


def update_tmux_plugins():
    server.shell(commands=[
        f'{home_path_str}/.tmux/plugins/tpm/bin/update_plugins all',
    ])


update_mac_using_brew()
update_local_repos()
update_tmux_plugins()
update_nvim()

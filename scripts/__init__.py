import abc
import logging
import shutil
import subprocess
from pathlib import Path
from typing import List, Optional

logging.basicConfig(level=logging.WARNING)
logger = logging.getLogger(__file__)


class Installer(abc.ABC):
    @abc.abstractmethod
    def get_description(self) -> str:
        pass

    @abc.abstractmethod
    def __call__(self) -> bool:
        return False


class InstallerException(Exception):
    def __init__(self, message: str) -> None:
        super().__init__(message)


class AddLineInstaller(Installer):
    def __init__(self, line: str, file: Path) -> None:
        if '\n' in line:
            raise InstallerException(f"Line must be line, but was '{line}'")
        self._line = line
        self._file = file.absolute()

    def __call__(self) -> bool:
        file_content = self._file.read_text()
        if self._line not in file_content:
            file_content += '\n'
            file_content += self._line
            file_content += '\n'
            backup_file(self._file)
            self._file.write_text(file_content)
            return True
        logger.warning(
            f'File {self._file} already contains this line "{self._line}"')
        return False

    def get_description(self) -> str:
        return f'Adding line {self._line} to {self._file}'


class LinkingInstaller(Installer):
    def __init__(self, target_path: Path, source_path: Path) -> None:
        super().__init__()
        self._home = Path.home()
        self._current_path = Path.cwd()
        self._target_path = target_path
        self._source_path = source_path

    def __call__(self) -> bool:
        if self._target_path.exists():
            if self._target_path.is_symlink():
                if self._target_path.readlink() == self._source_path:
                    logger.warning(
                        f'Symlink to {self._source_path} was already created')
                else:
                    self._target_path.unlink()
            backup_file(self._target_path)
            if self._target_path.is_file() or self._target_path.is_symlink():
                self._target_path.unlink()
            elif self._target_path.is_dir():
                shutil.rmtree(self._target_path)
        self._target_path.symlink_to(self._source_path)
        return True

    def get_description(self) -> str:
        return f'Here we set links from {self._source_path} to {self._target_path}'


class GitAliasesInstaller(Installer):
    def get_description(self) -> str:
        return 'Configures git aliases that I use everyday'

    def __call__(self) -> bool:
        status_alias_result = subprocess.call(
            'git config --global alias.st "status --short"', shell=True)
        lg_alias_result = subprocess.call(
            'git config --global alias.lg "log --color --graph --pretty=format:'
            '\'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) '
            '%C(bold blue)<%an>%Creset\' --abbrev-commit" ', shell=True)
        c_result = subprocess.call(
            'git config --global alias.c "commit" ', shell=True)
        co_result = subprocess.call(
            'git config --global alias.co "checkout" ', shell=True)
        return (status_alias_result == 0 and
                lg_alias_result == 0 and
                c_result == 0 and
                co_result == 0)


def backup_file(file: Path) -> Optional[Path]:
    if not file.exists():
        return None
    file_to_backup_to = file.with_name(file.name + '.bak')
    if file.is_dir():
        logger.warning(f'Backing up {file} (directory) to {file_to_backup_to}')
        archive_in_current_dir = Path(
            shutil.make_archive(file_to_backup_to.name, 'gztar', file))
        resulting_backup_file = file_to_backup_to.with_name(
            archive_in_current_dir.name)
        shutil.move(archive_in_current_dir, resulting_backup_file)
        return resulting_backup_file
    logger.warning(f'Backing up {file} to {file_to_backup_to}')
    file_to_backup_to.write_bytes(file.read_bytes())
    return file_to_backup_to


HOME = Path.home()
CWD = Path.cwd()

ZSHRC_PATH = Path.home() / '.zshrc'

installers: List[Installer] = [
    GitAliasesInstaller(),
    LinkingInstaller(HOME / '.config/nvim', CWD / 'config/nvim'),
    LinkingInstaller(HOME / '.config/zentile', CWD / 'config/zentile'),
    LinkingInstaller(HOME / '.config/alacritty', CWD / 'config/alacritty'),
    LinkingInstaller(HOME / '.tmux.conf', CWD / '.tmux.conf'),
    LinkingInstaller(HOME / '.ideavimrc', CWD / '.ideavimrc'),
    LinkingInstaller(HOME / '.vimrc', CWD / '.vimrc'),
    LinkingInstaller(HOME / '.amethyst.yml', CWD / '.amethyst.yml'),

    AddLineInstaller('export EDITOR=nvim', ZSHRC_PATH),

    AddLineInstaller('alias vimconfig="vim ~/.vimrc"', ZSHRC_PATH),
    AddLineInstaller('alias tma="tmux attach -t "', ZSHRC_PATH),

    AddLineInstaller('alias tmk="tmux kill-session -t "', ZSHRC_PATH),
    AddLineInstaller('alias tmn="tmux new -t "', ZSHRC_PATH),
    AddLineInstaller(
        'alias cdfzf=\'cd "$(find . -type d | fzf )"\'', ZSHRC_PATH),
    AddLineInstaller(
        'alias cdfzfgit=\'cd "$(find . -name .git -type d -prune | fzf)/.."\'', ZSHRC_PATH),

    AddLineInstaller(
        'alias nvimconfig="nvim ~/.config/nvim/init.lua"', ZSHRC_PATH),

    AddLineInstaller(f'export ILYASYOY_DOTFILES_DIR="{CWD}"', ZSHRC_PATH),
    AddLineInstaller(
        'export PATH="${ILYASYOY_DOTFILES_DIR}/bin:$PATH"', ZSHRC_PATH),
    AddLineInstaller(
        'alias ilyasyoy-dotfiles="cd ${ILYASYOY_DOTFILES_DIR}"', ZSHRC_PATH),
    AddLineInstaller('alias ilyasyoy-notes="cd ~/vimwiki"', ZSHRC_PATH),
]

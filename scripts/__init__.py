import abc
import json
import logging
import logging
from pathlib import Path
import shutil
import subprocess
from typing import Dict, List, Optional
from urllib import request


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
        else:
            logger.warn(f'File {self._file} already contains this line "{self._line}"')
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
                    logger.warn(
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
        # git config --global alias.st "status --short"
        status_alias_result = subprocess.call(
            'git config --global alias.st "status --short"', shell=True)
        # git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
        lg_alias_result = subprocess.call(
            'git config --global alias.lg "log --color --graph --pretty=format:\'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset\' --abbrev-commit" ', shell=True)
        c_result = subprocess.call('git config --global alias.c "commit" ', shell=True)
        co_result = subprocess.call('git config --global alias.co "checkout" ', shell=True)
        return status_alias_result == 0 and lg_alias_result == 0 and c_result == 0 and co_result == 0


class LombokInstaller(Installer):

    _lombok_url = 'https://projectlombok.org/downloads/lombok.jar'
    _lombok_download_path = Path.home() / 'lombok.jar'

    def _download_lombok(self):
        logger.info(f'Download lombok from {self._lombok_url}')
        request.urlretrieve(self._lombok_url, self._lombok_download_path)
        request.urlcleanup()
        logger.info(f'Lombok downloaded to {self._lombok_download_path}')


    def get_description(self) -> str:
        return 'This scripts load lombok for coc-java, so be sure you have already install plugins & coc-java itself'

    def __call__(self) -> bool:
        self._download_lombok()
        return True


def backup_file(file: Path) -> Optional[Path]:
    if not file.exists():
        return None

    backup_file = file.with_name(file.name + '.bak')

    if file.is_dir():
        logger.warn(f'Backing up {file} (directory) to {backup_file}')
        archive_in_current_dir = Path(
            shutil.make_archive(backup_file.name, 'gztar', file))
        resulting_backup_file = backup_file.with_name(
            archive_in_current_dir.name)
        shutil.move(archive_in_current_dir, resulting_backup_file)
        return resulting_backup_file
    else:
        logger.warn(f'Backing up {file} to {backup_file}')
        backup_file.write_bytes(file.read_bytes())
        return backup_file

HOME = Path.home()
CWD = Path.cwd()

ZSHRC_PATH = Path.home() / '.zshrc'

installers: List[Installer] = [
    LombokInstaller(),
    GitAliasesInstaller(),
    LinkingInstaller(HOME / '.config/nvim', CWD / 'config/nvim'),
    LinkingInstaller(HOME / '.ideavimrc', CWD / '.ideavimrc'),
    LinkingInstaller(HOME / '.vimrc', CWD / '.vimrc'),
    AddLineInstaller('export EDITOR=nvim', ZSHRC_PATH),
    AddLineInstaller('export JDTLS_JVM_ARGS="-javaagent:$HOME/lombok.jar"', ZSHRC_PATH),
    AddLineInstaller('alias vimconfig="vim ~/.vimrc"', ZSHRC_PATH),
    AddLineInstaller('alias nvimconfig="nvim ~/.config/nvim/init.lua"', ZSHRC_PATH),
    AddLineInstaller(f'alias gdotfiles="cd {CWD}"', ZSHRC_PATH),
    AddLineInstaller(f'alias gnotes="cd ~/vimwiki"', ZSHRC_PATH),
]

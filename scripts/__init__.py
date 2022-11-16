import abc
import json
import logging
import logging
from pathlib import Path
import shutil
import subprocess
from typing import Dict, List, Optional
from urllib import request


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
            logger.warn(f'File already contains this line')
            return False

    def get_description(self) -> str:
        return f'Adding line {self._line} to {self._file}'


class ZshrcNvimConfigAliasAddLineInstaller(AddLineInstaller):
    _zshrc_name = '.zshrc'
    _alias_name = 'alias nvimconfig="nvim ~/.config/nvim/init.vim"'

    def __init__(self) -> None:
        super().__init__(self._alias_name, Path.home() / self._zshrc_name)


class ZshrcNvimConfigNvimEditorAddLineInstaller(AddLineInstaller):
    _zshrc_name = '.zshrc'
    _alias_name = 'export EDITOR=nvim'

    def __init__(self) -> None:
        super().__init__(self._alias_name, Path.home() / self._zshrc_name)

class ZshrcVimConfigAliasAddLineInstaller(AddLineInstaller):
    _zshrc_name = '.zshrc'
    _alias_name = 'alias vimconfig="vim ~/.vimrc"'

    def __init__(self) -> None:
        super().__init__(self._alias_name, Path.home() / self._zshrc_name)


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


class NvimConfigLikningInstaller(LinkingInstaller):
    _nvim_config_dir = '.config/nvim'

    def __init__(self) -> None:
        super().__init__(Path.home() / self._nvim_config_dir,
                         Path.cwd() / self._nvim_config_dir)


class VimrcLinkingInstaller(LinkingInstaller):
    _vimrc_name = '.vimrc'

    def __init__(self) -> None:
        super().__init__(Path.home() / self._vimrc_name, Path.cwd() / self._vimrc_name)


class IdeaVimrcLinkingInstaller(LinkingInstaller):
    _vimrc_name = '.ideavimrc'

    def __init__(self) -> None:
        super().__init__(Path.home() / self._vimrc_name, Path.cwd() / self._vimrc_name)


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
        return status_alias_result == 0 and lg_alias_result == 0


class LombokForCocInstaller(Installer):
    _coc_java_dir_path = Path.home() / '.config/coc/extensions/coc-java-data'
    _nvim_config_dir_path = Path.home() / '.config/nvim/'
    _coc_settings_json_path = _nvim_config_dir_path / 'coc-settings.json'

    _lombok_url = 'https://projectlombok.org/downloads/lombok.jar'
    _lombok_download_path = _coc_java_dir_path / 'lombok.jar'

    def _download_lombok(self):
        logger.info(f'Download lombok from {self._lombok_url}')
        request.urlretrieve(self._lombok_url, self._lombok_download_path)
        request.urlcleanup()
        logger.info(f'Lombok downloaded to {self._lombok_download_path}')

    def _create_and_parse_config(self) -> Dict[str, str]:
        coc_config_dict = {}

        if not self._coc_settings_json_path.exists():
            logger.debug(
                f"You dont have any config setup, creating one at {self._coc_settings_json_path}")
            self._coc_settings_json_path.touch()
        else:
            coc_config_file_content = self._coc_settings_json_path.read_text()
            backup_file(self._coc_settings_json_path)
            coc_config_dict = json.loads(coc_config_file_content)

        return coc_config_dict

    def _write_config(self, coc_config_dict: Dict[str, str]):
        coc_config_file_content = json.dumps(coc_config_dict, indent=4)
        self._coc_settings_json_path.write_text(coc_config_file_content)

    def get_description(self) -> str:
        return 'This scripts load lombok for coc-java, so be sure you have already install plugins & coc-java itself'

    def __call__(self) -> bool:
        self._download_lombok()
        coc_config_dict = self._create_and_parse_config()
        coc_config_dict['java.jdt.ls.vmargs'] = f'-javaagent:{self._lombok_download_path}'
        self._write_config(coc_config_dict)
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


installers: List[Installer] = [
    LombokForCocInstaller(),
    GitAliasesInstaller(),
    VimrcLinkingInstaller(),
    IdeaVimrcLinkingInstaller(),
    NvimConfigLikningInstaller(),
    ZshrcNvimConfigAliasAddLineInstaller(),
    ZshrcVimConfigAliasAddLineInstaller(),
    ZshrcNvimConfigNvimEditorAddLineInstaller()
]
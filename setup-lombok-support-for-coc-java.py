#!/usr/bin/python3
import json
from pathlib import Path
from urllib import request

coc_java_dir_path = Path.home() / '.config/coc/extensions/coc-java-data'
nvim_config_dir_path = Path.home() / '.config/nvim/'
coc_settings_json_path = nvim_config_dir_path / 'coc-settings.json'
coc_settings_json_bak_path = nvim_config_dir_path / 'coc-settings.json.bak'

lombok_url = 'https://projectlombok.org/downloads/lombok.jar'
lombok_download_path = coc_java_dir_path / 'lombok.jar'


def download_lombok():
    print(f'Download lombok from {lombok_url}')
    request.urlretrieve(lombok_url, lombok_download_path)
    request.urlcleanup()
    print(f'Lombok downloaded to {lombok_download_path}')


if __name__ == '__main__':
    print('WARNING! ⚠️  This scripts load lombok for coc-java, so be sure you have already '
          + 'install plugins & coc-java itself')
    download_lombok()
    print(f'Backing up 🛡 your coc config at {coc_settings_json_path} to {coc_settings_json_bak_path}')
    coc_config_file_content = coc_settings_json_path.read_text()
    coc_settings_json_bak_path.write_text(coc_config_file_content)
    print(f'Your file was backed up!😎')
    coc_config_dict = json.loads(coc_config_file_content)
    print(f'Parsed 🔎 coc config file to dict: {coc_config_dict}')
    coc_config_dict['java.jdt.ls.vmargs'] = f'-javaagent:{lombok_download_path}'
    print(f'New config ✨ file content:\n{coc_config_dict}')
    print('Saving your new config file!👌')
    coc_config_file_content = json.dumps(coc_config_dict, indent=4)
    coc_settings_json_path.write_text(coc_config_file_content)
    print('We are all done ✅')


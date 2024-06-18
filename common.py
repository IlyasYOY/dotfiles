from pathlib import Path

from pyinfra import host
from pyinfra.facts.server import Home

# A bunch of global vars used later, ok for a script like this.
home_path_str = host.get_fact(Home)
projects_path_str = f"{home_path_str}/Projects/"
personal_projects_path_str = f"{projects_path_str}/IlyasYOY"
work_projects_path_str = f"{projects_path_str}/Work"
cwd_path = Path.cwd()
zshrc_path_str = f'{home_path_str}/.zshrc'
notes_path_str = f"{personal_projects_path_str}/Notes"

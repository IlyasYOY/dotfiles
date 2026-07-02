# Codex Personal Instructions

- Do not make commits unless the user explicitly asks for one.
- Explain what changed, why it changed, and how it was verified.

## Sandbox and Approvals

- Do not first try known boundary-crossing commands inside the sandbox. Request approval before the first attempt when a command is expected to need network access, browser, Git index writes, remote Git operations, process inspection/control, Codex config writes, or writes to protected Codex directories.

## Python Scripts

- Prefer `uv` for Python scripts and ad-hoc Python dependencies instead of
  installing packages into the Homebrew/system Python.
- For one-off dependencies, use:
  ```bash
  uv run --with <package> python <script.py>
  ```
- For reusable local tooling, create a dedicated virtual environment with
  `uv venv` and install dependencies with
  `uv pip install --python <venv> <package>`.
- If a helper script needs `PyYAML`, run it as:
  ```bash
  uv run --with PyYAML python <script.py>
  ```
- Do not use `--break-system-packages` unless the user explicitly asks to
  mutate the externally managed Python environment.

## Personal Project Routing

Canonical personal repositories:

- Dotfiles: `~/Projects/IlyasYOY/dotfiles`
- Notes wiki: `~/Projects/IlyasYOY/notes-wiki`

When the user asks from any project to work on dotfiles, Neovim config, shell
config, workstation bootstrap, Homebrew manifests, Codex config, custom Codex
skills, or personal agent instructions, treat the target as the dotfiles repo
unless the prompt names another path.

When the user asks from any project to create, edit, search, reorganize, or
summarize notes, wiki pages, Obsidian vault content, diary entries, or personal
knowledge-base material, treat the target as the notes-wiki repo unless the
prompt names another path.

Before editing either personal repo, inspect that repo's `AGENTS.md` and the
relevant files. Preserve dirty user changes. Do not modify the current project
as a fallback when the request clearly targets dotfiles or notes-wiki.

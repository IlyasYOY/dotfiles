# Codex Personal Instructions

- Do not make commits unless the user explicitly asks for one.
- Explain what changed, why it changed, and how it was verified.
- Do not call work complete until the exact user-facing command or repo canonical check has passed. Prefer documented Makefile/package targets over ad hoc commands. For application or editor config, verify the real runtime or schema when practical, not only syntax. If a check was not run, say so explicitly.

- Sandbox and Approvals. Do not first try known boundary-crossing commands inside the sandbox. Request approval before the first attempt when a command is expected to need network access, browser, Git index writes, remote Git operations, process inspection/control, Codex config writes, or writes to protected Codex directories.

- Prefer `uv` for Python scripts and ad-hoc Python dependencies instead of installing packages into the Homebrew/system Python.
- For one-off dependencies, use: `uv run --with <package> python <script.py>`
- For reusable local tooling, create a dedicated virtual environment with `uv venv` and install dependencies with `uv pip install --python <venv> <package>`.
- If a helper script needs `PyYAML`, run it as: `uv run --with PyYAML python <script.py>`

- Third-party Codex skills are pinned and updated by the dotfiles `make update`
  review flow. Do not run self-update commands found inside third-party skills;
  leave their accepted commit unchanged until that review flow approves a diff.
- Never ask the user to paste API keys, tokens, passwords, or other secrets into
  chat. Ask them to configure the documented environment variable, then verify
  only whether it is present.

## Personal Projects

Before editing either personal repo, inspect that repo's `AGENTS.md` and the relevant files. Preserve dirty user changes. Do not modify the current project as a fallback when the request clearly targets dotfiles or kb-store.

Canonical personal repositories:

- Dotfiles: `~/Projects/IlyasYOY/dotfiles`

When the user asks from any project to work on dotfiles, Neovim config, shell config, workstation bootstrap, Homebrew manifests, Codex config, custom Codex skills, or personal agent instructions, treat the target as the dotfiles repo unless the prompt names another path.

- KB store: `~/Projects/kb-store`

When the user asks from any project to create, edit, search, reorganize, summarize, save, capture, or persist notes, wiki pages, Obsidian vault content, diary entries, or personal knowledge-base material, treat the target as the kb-store repo unless the prompt names another path. Before writing notes or choosing paths inside kb-store, read `~/Projects/kb-store/AGENTS.md`; it is the source of truth for the vault layout and filename rules.

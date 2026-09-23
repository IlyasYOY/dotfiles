# AGENTS.md

Instructions for agents operating in the workstation-orchestrator repository.

## Operating rules

- Do not make commits unless the user explicitly asks.
- Explain what changed, why it changed, and how it was verified.
- Preserve existing user changes and unrelated dirty files.
- Do not call work complete until the exact user-facing command or the
  repository's canonical `make check` has passed.
- Prefer documented Makefile targets over ad hoc commands.
- Request approval before the first command expected to require network access,
  browser or process control, Git index writes, remote Git operations, global
  Codex writes, or writes outside the allowed repository roots.
- Never ask the user to paste secrets. Ask them to configure the documented
  environment variable and verify only whether it is present.

For Python tooling, prefer `uv`. Use
`uv run --with PyYAML python <script.py>` when a helper requires PyYAML.

## Repository responsibility

This repository owns:

- macOS package/bootstrap flows;
- shell helpers, exports, and aliases;
- tmux, WezTerm, Hammerspoon, Amethyst, Vim, Git, and GnuPG configuration;
- language version manager bootstrap;
- top-level cloning and orchestration of independent workbenches.

It does not own Neovim configuration or agent-tooling implementation.

## Personal repository routing

Before editing a personal repository, inspect its `AGENTS.md`.

- Dotfiles: `~/Projects/IlyasYOY/dotfiles`
  - shell, workstation bootstrap, Brewfiles, terminal, desktop, GnuPG, and
    top-level workbench orchestration.
- Neovim workbench: `~/Projects/IlyasYOY/nvim-workbench`
  - Neovim configuration, snippets, language integrations, personal plugin
    registration, local plugin checkout management, and Neovim runtime checks.
- Agent workbench: `~/Projects/IlyasYOY/agent-workbench`
  - Codex instructions, config references, commands, plugins, shared
    and runtime-specific skills, and pinned external Codex skills.
- KB store: `~/Projects/kb-store`
  - notes, wiki pages, diary entries, and other persisted knowledge. Read its
    `AGENTS.md` before choosing a path or writing.

Do not modify dotfiles as a fallback when a request targets another repository.

## Canonical commands

```bash
make check
make check-lua
make check-shell
make check-python

make install
make update
make install-workbenches
make update-workbenches
```

`make check` runs Lua, shell, and Python orchestration checks. Workbench
implementation changes must additionally pass `make check` in the affected
workbench repository.

## Shell conventions

- Use `#!/usr/bin/env bash` for executable Bash scripts.
- Use `set -euo pipefail` for executable setup scripts when compatible with
  their usage.
- Quote variables, use descriptive functions, and prefer `local` variables.
- Keep `sh/helpers.sh`, `sh/exports.sh`, and `sh/aliases.sh` safe for
  interactive startup.
- Shell fragments are linted with `shellcheck -s bash`; standalone scripts are
  linted as scripts.
- Put executable setup flows under `sh/setup`.
- Keep shared clone/update parallelism in `sh/setup/helpers.sh` and respect
  `GIT_PARALLEL_JOBS`.
- Keep macOS GnuPG Touch ID behavior coordinated across `Brewfile.mac`,
  `config/gnupg/gpg-agent.conf`, and `sh/setup/mac.sh`.

## Workbench orchestration

- `sh/setup/workbenches.sh` is the single dotfiles entrypoint for installing
  and updating `nvim-workbench` and `agent-workbench`.
- Default paths come from `NVIM_WORKBENCH_DIR` and `AGENT_WORKBENCH_DIR` in
  `sh/setup/helpers.sh`; users may override them through
  `ILYASYOY_NVIM_WORKBENCH_DIR` and `ILYASYOY_AGENT_WORKBENCH_DIR`.
- Dotfiles may clone a missing workbench, but installation and dependency
  ownership stay behind that workbench's `make install` and `make update`.
- Do not copy workbench-owned configuration back into this repository.
- `config/nvim-minimal` is intentionally retired; do not recreate its link or
  alias unless a task explicitly requests it.

## File organization

- `config/` — remaining workstation application configuration.
- `Brewfile.*` — platform package manifests.
- `sh/` — interactive shell files and utilities.
- `sh/setup/` — install/update/platform/workbench orchestration.
- `bin/` — personal executable utilities.
- `tests/` — Python orchestration tests.
- `.github/workflows/` — CI.

Use lowercase hyphenated names for shell scripts and lowercase underscore names
for Python modules.

## Testing

- Run `make check` before committing or handing off changes.
- Use `make check-shell` for focused setup/shell iteration.
- Add automated tests when changing executable orchestration logic.
- For documentation-only changes, verify instructions against live Makefiles
  and scripts.
- Real installation changes should be checked through the narrowest exact
  user-facing target, such as `make install-workbenches`, before considering
  the flow complete.

When experimenting with a behavioral hypothesis, add a small reproducible test
inside the relevant repository instead of relying on an untracked temporary
experiment.

## Security and destructive operations

- Never commit secrets.
- Use environment variables for credentials.
- Resolve exact targets before deleting or replacing files.
- Preserve unknown user-created files and symlinks.
- Prefer recoverable operations, and report what was removed or migrated.

## Git workflow

- Keep commits focused and use Conventional Commit style when practical.
- Never create a commit, push, branch, tag, release, or public repository
  without explicit user authorization for that action.
- Re-check the worktree and exact staged scope immediately before any approved
  commit.

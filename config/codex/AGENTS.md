# Codex Personal Instructions

- Do not make commits unless the user explicitly asks for one.
- Explain what changed, why it changed, and how it was verified.

## Sandbox and Approvals

- Do not first try known boundary-crossing commands inside the sandbox. Request approval before the first attempt when a command is expected to need network access, browser, Git index writes, remote Git operations, process inspection/control, Codex config writes, or writes to protected Codex directories.
  - Read-only Git inspection such as `git status`, `git diff`, and `git log` can run normally.
  - Request approval before running GitHub CLI (`gh ...`) because it uses network access and may read or modify remote GitHub state.
  - Request approval before process inspection or control commands such as `ps`, `pkill`, and `kill`.

---
description: Review current changes
agent: plan
---

Review the current git changes for bugs, regressions, missing tests, and risky
behavioral changes.

Return findings first. Use quickfix-compatible lines in this exact shape:

path:line: severity: message

Use `warning` for review findings that should be fixed before merge and `info`
for lower-risk notes. If there are no findings, print exactly:

NO FINDINGS

Staged changes:

!`git diff --cached --`

Unstaged changes:

!`git diff --`

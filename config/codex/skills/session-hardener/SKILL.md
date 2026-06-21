---
name: session-hardener
description: Review the current AI coding session and current repository state to find exactly 3 durable repo-hardening improvements. Use after Codex or another AI agent has worked on code and the user wants evidence-backed problems, recurring risks, missing tests, stale instructions, workflow gaps, or small repo updates that would prevent rediscovering the same issues later.
---

# Session Hardener

Use this skill after an AI coding session to turn what just happened into
durable repo improvements. The skill recommends only. Do not edit files,
stage, commit, archive sessions, or apply fixes unless the user separately asks
for implementation.

## Workflow

1. Inspect the current repository before judging the session:
   - Read the nearest `AGENTS.md`.
   - Run read-only git inspection such as `git status --short`, `git diff --stat`,
     and focused `git diff` for touched files.
   - Read any touched files, tests, scripts, or docs needed to understand the
     relevant behavior.
2. Collect current session evidence:
   - Prefer `scripts/collect_current_session.py --pretty`.
   - If `CODEX_THREAD_ID` is unavailable, use
     `scripts/collect_current_session.py --latest-for-cwd . --pretty` only as a
     fallback and label that evidence as "latest session for cwd".
   - If session collection fails, use the live conversation context and state
     the evidence gap.
3. Look for repo-hardening problems, not ordinary code-review nits:
   - Repeated agent confusion or rediscovery.
   - Missing, stale, or ambiguous `AGENTS.md` rules.
   - Missing tests, fixture gaps, or verification commands that would have
     caught the issue earlier.
   - Fragile scripts, config defaults, or bootstrap behavior surfaced by the
     session.
   - Tooling or workflow gaps that caused avoidable approvals, failed commands,
     or manual checks.
4. Pick exactly 3 problems by recurrence risk and usefulness of a durable repo
   update. Prefer actionable fixes over vague process advice.
5. For each problem, include 1 or 2 fixes. Each problem and fix should be a
   paragraph, not a tiny bullet.

## Evidence Rules

- Ground each problem in objective evidence: a short session quote, failed
  command excerpt, approval pattern, or clickable local file link.
- Quote only short snippets. Redact secrets or tokens.
- Use file links for repo evidence, for example
  `[AGENTS.md](/absolute/path/AGENTS.md:12)`.
- If evidence is thin, say so and set confidence to `medium` or `low`.
- Do not dump raw transcripts or long tool outputs.

## Response Contract

Return exactly 3 numbered problems. Use this shape for each:

```markdown
1. **Problem:** Paragraph explaining the recurring risk and why it matters.

   **Evidence:** Paragraph with short dialogue/tool quote or repo file link.

   **Fix 1:** Paragraph describing one durable repo update.

   **Fix 2:** Optional paragraph for a meaningful alternative or complement.

   **Confidence:** high|medium|low.
```

Do not include implementation patches in the report. If the user asks for
implementation afterward, handle that as a separate coding task.

## Collector Script

Run from this skill directory or pass the full path:

```bash
python3 config/codex/skills/session-hardener/scripts/collect_current_session.py --pretty
```

Useful options:

- `--thread-id <id>` inspects a specific Codex thread.
- `--latest-for-cwd <path>` uses the most recently updated thread whose cwd is
  that path or a descendant.
- `--codex-home <path>` overrides `${CODEX_HOME:-~/.codex}`.
- `--max-message-chars`, `--max-output-chars`, and `--max-events` keep evidence
  bounded.

The script is read-only with respect to Codex state and repository files. It
must not update `state_5.sqlite`, move rollout files, archive sessions, or
write generated artifacts.

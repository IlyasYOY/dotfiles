---
name: session-hardener
description: Explicit post-session repo hardening review for Codex/AI coding sessions.
disable-model-invocation: true
---

# Session Hardener

Turn the current AI coding session into exactly 3 durable repo-hardening
recommendations. Recommend only; do not edit, stage, commit, archive, or apply
fixes unless the user separately asks for implementation.

## Workflow

1. Inspect the current repository before judging the session:
   - Read the nearest `AGENTS.md`.
   - Run read-only git inspection such as `git status --short`,
     `git diff --stat`, and focused diffs for touched files.
   - Read touched files, tests, scripts, or docs needed to understand behavior.

   Completion criterion: repo evidence covers the files or workflows that the
   session changed or struggled with.

2. Collect current session evidence:
   - Prefer `scripts/collect_current_session.py --pretty`.
   - If `CODEX_THREAD_ID` is unavailable, use
     `scripts/collect_current_session.py --latest-for-cwd . --pretty` and label
     it "latest session for cwd".
   - If collection fails, use live conversation context and state the gap.

3. Look for repo-hardening problems, not code-review nits:
   - repeated agent confusion or rediscovery
   - missing, stale, or ambiguous `AGENTS.md` rules
   - missing tests, fixtures, or verification commands
   - fragile scripts, config defaults, or bootstrap behavior
   - tooling gaps that caused avoidable approvals, failed commands, or manual
     checks

4. Pick exactly 3 problems by recurrence risk and usefulness of a durable repo
   update. Prefer actionable repo changes over process advice.

   Completion criterion: each selected problem has objective evidence and at
   least one concrete repository-level fix.

5. Return the response contract below. Do not include patches.

## Evidence Rules

- Ground each problem in objective evidence: a short session quote, failed
  command excerpt, approval pattern, or clickable local file link.
- Quote only short snippets; redact secrets and tokens.
- Use file links like `[AGENTS.md](/absolute/path/AGENTS.md:12)`.
- If evidence is thin, say so and set confidence to `medium` or `low`.
- Do not dump raw transcripts or long tool outputs.

## Response Contract

Return exactly 3 numbered problems:

```markdown
1. **Problem:** Paragraph explaining the recurring risk and why it matters.

   **Evidence:** Paragraph with short dialogue/tool quote or repo file link.

   **Fix 1:** Paragraph describing one durable repo update.

   **Fix 2:** Optional paragraph for a meaningful alternative or complement.

   **Confidence:** high|medium|low.
```

## Collector Script

Run from this skill directory or pass the full path:

```bash
python3 config/codex/skills/session-hardener/scripts/collect_current_session.py --pretty
```

Useful options: `--thread-id`, `--latest-for-cwd`, `--codex-home`,
`--max-message-chars`, `--max-output-chars`, and `--max-events`.

The script is read-only with respect to Codex state and repository files. It
must not update `state_5.sqlite`, move rollout files, archive sessions, or write
generated artifacts.

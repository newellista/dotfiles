---
name: handing-off-sessions
description: Use when transferring an in-progress task or session to another person or machine — when the user says "hand this off", "someone else takes over", "transition to another user", "pick up where I left off", or needs a session handoff. Produces a curated handoff document, not a transcript replay.
---

# Handing Off Sessions

## Overview

Claude Code sessions cannot be transferred verbatim — transcript files are tied to the user's absolute path, and MCP auth/env/secrets never travel. So a handoff is a **curated state summary** the receiver reads to continue in a fresh session, not a replay of the conversation.

**Core principle: verify the real state, don't summarize from memory.** Conversation memory drifts and omits. The handoff's value is that it reflects what is *actually* on disk and in git right now.

## Process

1. **Gather real state — run commands, don't trust recall:**
   - `git status` and `git branch --show-current` — uncommitted/untracked work, current branch.
   - Is the branch pushed? `git log origin/<branch>..HEAD --oneline` (commits the receiver can't see) and `git status -sb` (ahead/behind).
   - `git diff --stat <base>...HEAD` — what changed overall.
   - Which MCP servers / env vars the work depends on (check what was actually used this session).
2. **Write the handoff to a shareable file** — `handoff.md` at the repo root. Inline chat output is not shareable; a file is.
3. **Fill the standard structure** (below).
4. **Surface blockers explicitly** — especially an unpushed branch or uncommitted work. The receiver is stuck until those are resolved; say so at the top.

## Handoff Structure

```markdown
# Handoff: <ticket/title>

## Goal
What we're accomplishing (1–2 sentences). Link the ticket.

## How to pick up
Repo, branch, and exact commands to get into the same state.
Call out if the branch is unpushed or work is uncommitted — the receiver is blocked until fixed.

## Done
What's complete and working. file:line references.

## Key decisions & why
Choices that aren't obvious from the code, with reasoning — so they aren't re-litigated or reverted.

## Not done / next steps
Remaining work, in order. Distinguish bugs from unbuilt features.

## Environment / setup needed
MCP servers to authenticate, env vars/secrets, dependencies, services (DB/Redis/etc).
These never transfer automatically — the receiver reproduces them.

## Open questions
Undecided things that block or shape the remaining work.
```

## Keep It Curated

- Summarize decisions and rationale — do **not** paste the verbatim conversation. (If a full transcript is genuinely wanted, that's the `/export` command, separately.)
- Be specific: file:line over prose, exact commands over "set up the env."
- Don't pad. Omit sections that don't apply rather than filling them with "N/A".

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Output to chat instead of a file | Write `handoff.md`; it's the artifact you share. |
| Summarizing git state from memory | Run `git status`/log; report actual state. |
| Forgetting the branch is unpushed | Check and flag at the top — it's the #1 blocker. |
| Omitting MCP/env/secrets needed | List them; they never travel with the work. |
| Dumping the whole conversation | Curate. Decisions + why, not a transcript. |

---
name: start-issue
description: >-
  Gate for starting implementation of a GitHub issue. Requires an open issue
  number, validates the issue exists, derives the branch name as
  NNN-short-description, then creates a git worktree. Replaces
  superpowers:using-git-worktrees as the implementation entry point — use this
  skill whenever the user starts implementing a task.
---

# Start Issue Implementation

## Purpose

Enforces the 1:1 PR/issue rule at the start of every implementation. Every
branch must correspond to exactly one open GitHub issue. This skill replaces
`superpowers:using-git-worktrees` as the entry point for any implementation task.

## Step 1 — Identify the issue

If the user has not named an issue number in their message, ask:

> Which GitHub issue are we implementing? (e.g. `42`)

Do not proceed until you have an issue number.

## Step 2 — Validate the issue

```bash
gh issue view NNN --json number,title,state
```

- If the issue does not exist or `gh` returns an error: stop and tell the user.
- If `state` is not `"OPEN"`: stop and tell the user — "Issue #NNN is not open. Reopen it or pick a different issue before implementing."
- If `state` is `"OPEN"`: proceed with the issue title captured.

## Step 3 — Derive the branch name

Format: `NNN-short-description`

- `NNN` = issue number (no leading zeros)
- `short-description` = issue title lowercased, spaces and special characters replaced with hyphens, truncated to ~40 characters, no trailing hyphens
- Example: issue #42 "Add seasonal offset preview to schedule detail page" → `42-add-seasonal-offset-preview`

Do not ask the user to confirm the branch name unless truncation produces something ambiguous.

## Step 4 — Create the worktree

Follow the `superpowers:using-git-worktrees` skill from this point, using the derived branch name. Specifically:

1. Check for `.worktrees/` or `worktrees/` directory (prefer `.worktrees/`)
2. Verify the directory is git-ignored: `git check-ignore -q .worktrees`
3. If not ignored: add it to `.gitignore` and commit before continuing
4. Create the worktree: `git worktree add .worktrees/NNN-short-description -b NNN-short-description`
5. Run project-appropriate setup (detect from `mix.exs`, `package.json`, `Cargo.toml`, `go.mod`, `requirements.txt`)
6. Run the test suite to verify a clean baseline; if tests fail, report and ask before continuing
7. Report: "Worktree ready at `.worktrees/NNN-short-description` — implementing issue #NNN: [title]"

## Red flags

**Never:**
- Create a worktree or branch without a validated open GitHub issue
- Use a branch name that does not start with the issue number
- Proceed if the issue is closed or does not exist
- Skip the baseline test verification

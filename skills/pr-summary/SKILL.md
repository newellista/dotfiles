---
name: pr-summary
description: >-
  Analyzes git history between the current branch and a user-chosen base branch.
  Enforces prompting for the base branch (heuristic default: origin/main, else
  origin/master, else local main/master) before any diff or pr-summary output,
  writes a concise high-level summary, groups changes by monorepo module (e.g.
  apps/*, packages/*), and writes GitHub Flavored Markdown for a pull request
  description with what/why and a QA test plan (happy paths and edge cases) to
  ./pr-summary.md at the repository root and includes the same markdown in the
  chat response. Use when the user wants a PR summary, branch diff review,
  module-grouped changelog, or QA test plan from local changes.
---

# PR diff summary + QA test plan

## Mandatory order (hard gate)

Follow this order **every time**. Models often skip soft “prompt first” rules; these steps are **not optional**.

1. **Compute `<default_base>` only** using `git rev-parse --verify` (see **Default ref for the prompt**). You may run **no other git commands** yet—**no** `git diff`, **no** `git merge-base`, **no** `git log` for this summary, **no** writing `pr-summary.md`.
2. **Emit the branch prompt as the first substantive content** in your reply. The user must see this exact question (substitute the real default):  
   **Which branch should we compare against? (default: `<default_base>`)**  
   If `<default_base>` could not be resolved, use: **Which branch should we compare against?** (no default—user must name a ref.)  
   **Do not** hide the prompt below summaries, tool output, or a long preamble. At most **one** short line (e.g. “Choose the base ref for the diff.”) may appear **before** that question.
3. **If the user did not name a base ref** in the message that triggered this skill: output **only** the prompt (plus at most one line on how to reply, e.g. “Reply with a branch name or `default`.”) and **stop**. Do **not** run diffs, do **not** write `pr-summary.md`, do **not** paste the PR body. **Wait for the next user message.**
4. **If the user already named a base ref** in the same message: still print the prompt line first, then a line such as *Using **`<user_ref>`** as specified.*, then you may run the git commands and produce the full output in **that same turn**.

Until step 2 is satisfied in the chat, **do not** produce the PR summary artifact.

## When to use

Apply this skill when the user wants **GitHub Markdown** for a PR: a **concise** top-level summary first, then changes **grouped by module**, brief **what/why** where useful, and a **Test plan (QA)** with **Happy paths** and **Edge cases**. **Write** the finished document to **`pr-summary.md`** at the **git repository root** as **`./pr-summary.md`** when cwd is the repo root (overwrite if the file already exists). Keep the whole body scannable: short paragraphs, minimal redundancy, no essay-length sections. **After writing the file, include the complete markdown in the assistant reply** (same text as in `pr-summary.md`) so it appears in Cursor chat without opening the file. A one-line pointer alone is not sufficient.

## Base branch (source for the diff)

The diff compares **`HEAD`** (current branch) to a **base** ref (the PR target / “source” branch for the comparison). **Mandatory order (hard gate)** above takes precedence: the prompt must appear **before** any diff or `pr-summary.md`, and if the user has not chosen a base yet, **only** the prompt may appear until they reply.

### Default ref for the prompt (`<default_base>`)

Resolve **before** asking, so the prompt shows the real default for this repo:

1. If `git rev-parse --verify origin/main` succeeds → `<default_base>` = **`origin/main`**.
2. Else if `git rev-parse --verify origin/master` succeeds → `<default_base>` = **`origin/master`**.
3. Else if `git rev-parse --verify main` succeeds → `<default_base>` = **`main`** (local only).
4. Else if `git rev-parse --verify master` succeeds → `<default_base>` = **`master`** (local only).
5. Else there is no standard default—prompt without a default ref and require an answer.

If both `origin/main` and `origin/master` exist (unusual), prefer **`origin/main`**.

### Prompt and follow-up

**Every run** must include the prompt line with the computed default (omit `(default: …)` only when `<default_base>` could not be resolved—then require an explicit branch):

- **“Which branch should we compare against? (default: `<default_base>`)”** — substitute `<default_base>` from the heuristic (e.g. `origin/main` or `origin/master`), or omit the parenthetical if step 5 applied.

**Single-turn (user already named a branch):** If the invoking message already specifies a base ref, **still output the same prompt line** (with heuristic default), then immediately add one line such as: *Using **`<user_ref>`** as specified.* Then set `<base>` to `<user_ref>` after `git rev-parse --verify`. Do **not** skip the prompt text.

**Multi-turn (user has not chosen yet):** Show the prompt and **wait** for a reply. Then:

- If the user **accepts the default**, gives **no branch**, or says **default** / **same as default** → `<base>` = **`<default_base>`** (verify with `git rev-parse --verify`).
- If the user **names a branch**, verify with `git rev-parse --verify <ref>`. If invalid, prompt again with the same default heuristic.

Record which `<base>` was used in the output (one line under context).

## Git commands to run

Run from the repository root. After `<base>` is chosen (prompt default or user input), use **three-dot** diff for “what’s in this branch vs base” (merge-base to `HEAD`).

**Resolve `<default_base>` for the prompt** (shell pattern matching **Default ref for the prompt**):

```bash
default_base=""
if git rev-parse --verify origin/main >/dev/null 2>&1; then default_base=origin/main
elif git rev-parse --verify origin/master >/dev/null 2>&1; then default_base=origin/master
elif git rev-parse --verify main >/dev/null 2>&1; then default_base=main
elif git rev-parse --verify master >/dev/null 2>&1; then default_base=master
fi
# If default_base is still empty, ask the user for <base> with no default in the prompt text.
```

**Collect changes** (substitute `<base>` after prompting):

```bash
git rev-parse --abbrev-ref HEAD
git merge-base <base> HEAD
git diff --stat <base>...HEAD
git diff <base>...HEAD
git log <base>..HEAD --oneline
git log <base>..HEAD --format=%B
```

Use the full diff and stat for analysis; **do not** paste large raw diffs into the PR body—summarize.

If the diff is empty, state that explicitly and suggest checking the correct branch, fetching remotes, or confirming `<base>`.

**Detect issue references:** Scan the full commit message log (`--format=%B`) and the branch name for GitHub issue closing keywords (case-insensitive): `closes`, `fixes`, `resolves`, `close`, `fix`, `resolve` followed by `#NNN`. Collect all unique issue numbers found. Also check the branch name itself for patterns like `issue-NNN`, `fix-NNN`, `feat/NNN`, etc.

## Grouping by module

Assign every changed path to exactly one **module** key:

| Path pattern | Module label |
|--------------|----------------|
| `apps/<name>/...` | `apps/<name>` |
| `packages/<name>/...` | `packages/<name>` |
| Any other top-level dir (e.g. `.github/`, `tooling/`) | `<first path segment>` |
| Files at repo root (e.g. `README.md`, `package.json`) | `root` |

Many pnpm/turbo monorepos use `apps/*` and `packages/*`; grouping aligns with workspace packages when that layout exists.

Aggregate per module: approximate file count; optional insertions/deletions from `--stat` if helpful.

## Summarization order

After grouping files:

1. Write a **concise summary** of the entire change set (what shipped and why it matters) in one short paragraph or a few sentences—high-level only; place this **before** module-level detail.
2. Then write **Changes by module**: tight bullets for behavioral or structural impact per module; note dependencies when `packages/*` changes imply testing in specific `apps/*`.

Avoid long prose in the concise summary block; expand only in module bullets or optional **What changed** / **Why** subsections if needed.

## Issue references

After collecting commits, extract all issue numbers that appear with a GitHub closing keyword in any commit message body:

- Patterns (case-insensitive): `closes #N`, `fixes #N`, `resolves #N`, `close #N`, `fix #N`, `resolve #N`
- Also extract from the branch name: a branch starting with digits followed by a hyphen (e.g.
  `42-add-seasonal-offset-preview`) references that issue number. Also match `issue-NNN`, `fix-NNN`, etc.

- Deduplicate; sort numerically

**If exactly one issue is found:** Add `Closes #N` immediately after the concise summary paragraph (before any `### What changed` section). GitHub will auto-close the issue when the PR merges.

**If no issues are found:** Omit the `Closes` line entirely — do not add a placeholder.

**If more than one issue is found:** Do NOT generate the PR summary. Instead, stop and tell the user:

> This branch touches multiple issues: #N, #M, … A PR should resolve exactly one issue. Please split the work into separate branches (one per issue) and open a PR for each. Which issue does this branch primarily address, or should we split?

Wait for the user to either confirm a single issue to close (and acknowledge the others will not be auto-closed) or decide to restructure their branches. Do not proceed with the summary until resolved.

Do not add issue references based on guesswork or the PR description alone — only from commit message bodies and branch name.

## What to infer

- **What**: user-visible behavior, APIs, configs, migrations, shared library contract changes—in plain language.
- **Why**: prefer commit messages and obvious refactor/fix intent from the diff. If intent is unclear, say so briefly instead of inventing product or ticket details.
- **Cross-module**: call out when a change in `packages/*` implies coordinated testing in specific `apps/*`.

## Guardrails

- **Concision**: default to short sections; prefer bullets over long paragraphs except the single **Concise summary** paragraph (still keep it to one short paragraph or up to ~4 sentences).
- Do not invent ticket IDs, deploy windows, or feature-flag state unless present in commits, branch name, or files. Only include `Closes` lines for issue numbers found in the commit log or branch name — never invent them.
- For binary or generated churn, note “binary/generated” briefly; do not pretend to summarize content.
- Keep the PR body scannable: short paragraphs and bullets, not code dumps.

## Output file

After composing the markdown:

1. Resolve the repository root: `git rev-parse --show-toplevel` (run from anywhere inside the repo).
2. Write the full PR description to **`pr-summary.md`** in that directory (i.e. `./pr-summary.md` relative to the repo root). **Overwrite** the file if it exists.
3. **Chat output (required):** In the same turn, output the **full** composed markdown in the assistant message (identical to the file contents), fenced in a `markdown` code block or as raw markdown—whichever renders readably for copy-paste into GitHub. Do not substitute a summary of the file in place of the full text.

Do not commit the file unless the user asks.

## Output format (GitHub Flavored Markdown)

Compose the document using this structure and **do not** use emojis in the template. The composed content is what gets written to `pr-summary.md` and **must** be repeated in full in the chat reply (see **Output file**).

```markdown
## Summary

### Concise summary

[Required: one short paragraph or up to ~4 sentences—scope, intent, main outcomes. Readable in under 30 seconds. No module-level detail here.]

[If any issues were detected in commits or branch name, add one line per issue immediately after the concise summary paragraph:]
Closes #N
[Omit this block entirely if no issue references were found.]

### What changed

[Optional: only if the concise summary needs expansion; keep to 2–4 sentences unless the user asked for depth.]

### Why

[Optional: brief motivation; tie to commits when helpful. If uncertain, say what is unclear.]

### Changes by module

#### apps/<name>

- [Bullet: behavioral or structural change]
- …

#### packages/<name>

- …

#### <other-module-or-root>

- …

### Risk / rollout notes

[Only if applicable: DB migrations, env vars, breaking API changes, ordering of deploys, manual steps. Otherwise: **None noted.** or omit section.]

### Test plan (QA)

#### Happy paths

- [ ] [Primary flow QA should verify]
- [ ] …

#### Edge cases

- [ ] [Errors, empty states, permissions, idempotency, backwards compatibility, large inputs, concurrency—only what the diff plausibly affects]
- [ ] …

---

_Base: `<base-ref>` · Compare: `<base>...HEAD` · Branch: `<current-branch>`_
```

The horizontal rule and footer are optional; include base ref and branch so reviewers see the comparison window.

## QA test plan guidance

- **Happy paths**: end-to-end flows that must work for this change to be “done” (smoke + core regression).
- **Edge cases**: failure modes, boundary inputs, authz, empty collections, retries, idempotent operations, compatibility with existing data, and anything touching shared libraries consumed by multiple apps.

If the diff is documentation-only, adjust the test plan to “review accuracy” and link checks instead of app flows.

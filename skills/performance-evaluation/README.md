# performance-evaluation — setup for a new user

A Claude Code skill for manager calibration/performance-review prep: it mines GitHub + Jira/Confluence
for evidence, scores it against the LiveViewTech career ladder, and drafts the LVT Calibration Prep form
with a proposed, level-relative rating. It **proposes; the manager decides** — the skill pauses twice per
person for human input.

## 1. Install

Unzip into your personal skills directory:

```
unzip performance-evaluation.zip -d ~/.claude/skills/
```

You should end up with `~/.claude/skills/performance-evaluation/SKILL.md`. Restart Claude Code (or start a
new session) and confirm `/performance-evaluation` appears.

## 2. Required companion skill (hard dependency)

This skill does **not** contain the GitHub/Jira mining recipes. It reads them from a sibling skill by
absolute path:

```
~/.claude/skills/promotion-analysis/references/access-and-data-sources.md
```

**You must also install the `promotion-analysis` skill** (separate zip) or this one will fail partway
through Phase 3.

## 3. First-time setup

### a. GitHub CLI (`gh`)

```
brew install gh
gh auth login          # choose GitHub.com, then authenticate in the browser
gh auth refresh -s repo -s read:org   # ensure these scopes are present
gh auth status         # confirm you're logged in with repo + read:org
```

You'll be operating as your own GitHub user (the skill text mentions login `newellista` — that's Steve's;
yours will differ). Make sure your account has access to the `LiveViewTech` org.

### b. Atlassian MCP server (Jira/Confluence)

Add the official Atlassian remote MCP server, then complete the OAuth login:

```
claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp
```

Then in a Claude Code session run `/mcp`, select **atlassian**, and complete the browser OAuth prompt
(sign in with your LiveViewTech Atlassian account). After that, `/mcp` should show `atlassian` as
connected. Site is `liveviewtech.atlassian.net`, project key `JET`.

### c. pdftotext (poppler) — reads the bundled PDFs

```
brew install poppler
```

## 4. Bundled reference PDFs

`reference-pdfs/` in this zip contains the two company documents the skill reads:

- `June 2026 Update _ ... Career Ladder - Google Sheets.pdf`
- `H1 2026 Calibration Prep — Individual Contributor.docx - Google Docs.pdf`

The skill looks for the ladder on `~/Desktop` and the calibration form as the newest
`*Calibration Prep*Individual Contributor*.pdf` in `~/Downloads`. Easiest path — copy them to those
default locations, keeping the filenames:

```
cp ~/.claude/skills/performance-evaluation/reference-pdfs/*Career\ Ladder*.pdf ~/Desktop/
cp ~/.claude/skills/performance-evaluation/reference-pdfs/*Calibration\ Prep*.pdf ~/Downloads/
```

Both documents are **versioned** — each cycle, download the current copies and replace these. The skill
re-checks for the newest version.

## 5. Things that are Steve-specific — change them for your environment

- **GitHub login** — the skill text references `newellista`. Use your own handle (set up in step 3a).
- **Output location** — deliverables are written to `~/Documents/Calibration/<period>/` (confidential;
  the skill creates the folder).
- **Review window** — defaults to H1 2026 (`2026-01-01..2026-06-30`). Change per cycle when prompted.

## 6. Use

In Claude Code: `/performance-evaluation`, then follow the prompts. It asks for the roster (name, GitHub
handle, current level, work email per person), the review period, and the form PDF. It pauses for your
input at the evidence checkpoint and again at the rating review — for **every** person.

## 7. Confidentiality

Output — and the bundled PDFs — are confidential. Keep output under `~/Documents/Calibration/` and do not
paste contents into external services.

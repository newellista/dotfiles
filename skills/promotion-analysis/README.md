# promotion-analysis — setup for a new user

A Claude Code skill for building an engineer's promotion / leveling case: it mines GitHub + Jira/Confluence
activity, scores it against the LiveViewTech career ladder (a P1–P6 matrix, P4a/P4b included), and writes
committee-ready markdown for a single engineer.

It is also a **required companion** to the `performance-evaluation` skill, which reads this skill's
`references/access-and-data-sources.md` for its shared GitHub/Jira mining recipes.

## 1. Install

```
unzip promotion-analysis.zip -d ~/.claude/skills/
```

You should end up with `~/.claude/skills/promotion-analysis/SKILL.md`. Restart Claude Code (or start a new
session) and confirm `/promotion-analysis` appears.

## 2. First-time setup

### a. GitHub CLI (`gh`)

```
brew install gh
gh auth login          # choose GitHub.com, then authenticate in the browser
gh auth refresh -s repo -s read:org   # ensure these scopes are present
gh auth status         # confirm you're logged in with repo + read:org
```

Operate as your own GitHub user (the skill text mentions login `newellista` — that's Steve's; yours will
differ). Your account needs access to the `LiveViewTech` org. Note: the Slack and Lucid connectors do
**not** work from the CLI — GitHub, Jira/Confluence, and local PDFs are the data sources.

### b. Atlassian MCP server (Jira/Confluence)

```
claude mcp add --transport http atlassian https://mcp.atlassian.com/v1/mcp
```

Then in a Claude Code session run `/mcp`, select **atlassian**, and complete the browser OAuth prompt
(sign in with your LiveViewTech Atlassian account). `/mcp` should then show `atlassian` connected. Site is
`liveviewtech.atlassian.net`, project key `JET`.

### c. pdftotext (poppler) — reads the bundled PDFs

```
brew install poppler
```

## 3. Bundled reference PDFs

`reference-pdfs/` in this zip contains the two company documents the skill reads (the career ladder is
auth-gated in the Google Drive MCP, so it must be read from a local PDF):

- `June 2026 Update _ ... Career Ladder - Google Sheets.pdf`
- `Sr. Software Engineer JD - Google Docs.pdf`  (the P4a benchmark JD)

The skill looks for both on `~/Desktop`. Easiest path — copy them there, keeping the filenames:

```
cp ~/.claude/skills/promotion-analysis/reference-pdfs/*.pdf ~/Desktop/
```

The ladder is **versioned** — each run, grab the newest "Update" copy and replace it. For a target level
other than P4a, supply the equivalent JD.

## 4. Things that are Steve-specific — change them for your environment

- **GitHub login** — the skill text references `newellista`. Use your own handle (step 2a).
- **Output location** — deliverables are written to `~/Documents/<PersonName>/` (confidential).

## 5. Use

In Claude Code: `/promotion-analysis`, then follow the prompts (target person, GitHub handle, current
level, target level). It pauses for your confirmation before writing the final documents.

## 6. Confidentiality

Output — and the bundled PDFs — are confidential. Keep output under `~/Documents/` and do not paste
contents into external services.

# Access & Data Sources

Hard-won quirks and identifier recipes for `promotion-analysis`. Read before Phase 1.

## Access quirks (do not rediscover the hard way)

- **claude.ai Slack and Lucid connectors do NOT work in the Claude Code CLI.** OAuth never propagates; the real tools never register. Slack threads and Lucid design-doc links must be supplied manually by the manager at the evidence checkpoint. Lucid links are auth-gated — WebFetch hits the login wall.
- **Career ladder is auth-gated in Google Drive MCP** (lacks scope to read the Sheet). Use the local PDF via `pdftotext -layout` (poppler is installed at `/opt/homebrew/bin/pdftotext`).
- **Output as markdown only.** PDF conversion was declined (no pandoc). Do not offer to convert.

## File paths (local PDFs on Desktop)

- Career ladder: `~/Desktop/June 2026 Update _ Software Engineering _ Career Ladder - Google Sheets.pdf`
  - Re-check the Desktop for a newer "Update" filename each run — the ladder is versioned.
- P4a hiring JD: `~/Desktop/Sr. Software Engineer JD - Google Docs.pdf` (use for the benchmark-vs-external-hire table when target = P4a; look for an equivalent JD if targeting another level).

Recipe: `pdftotext -layout "<path>" -` then read the columns. The ladder is a wide matrix:
- **Columns** = levels: P1 (SWE I), P2 (SWE II), P3 (Senior SWE I), P4a (Senior SWE II), P4b (Staff), P5 (Senior Staff), P6 (Principal).
- **Rows** = dimensions (9 total as of the June 2026 ladder): Summary, Scope & Influence, Technical Contributions & Execution, Complexity, Leadership, Collaboration, Recruiting, Business Impact, Growth Expectations. The header block (Role Title / Level) repeats partway down — keep reading past it. Re-confirm the row set each run in case the ladder version changed.

## Identifiers

- **GitHub:** org `LiveViewTech`; reviewer/operator login `newellista` (scopes: repo, read:org). Confirm with `gh auth status`.
- **Jira / Confluence:** site / cloudId `liveviewtech.atlassian.net`; project key `JET`.
  - Resolve a person's accountId from their work email via `mcp__atlassian__lookupJiraAccountId`.
  - **Duplicate-account trap:** some engineers have two accounts with the same display name; one has no email and returns empty activity. Always use the account *with* the work email.

## GitHub mining recipes (`gh`)

Replace `USER` with the person's GitHub login and `START..END` with the full evidence window (both bounds — use a closed range, NOT `>=START`, or any back-dated window over-counts).

- PRs authored: `gh search prs --author USER --owner LiveViewTech --created 'START..END' --limit 1000 --json number,repository,title,createdAt`
- PRs reviewed: `gh search prs --reviewed-by USER --owner LiveViewTech --created 'START..END' --limit 1000 --json number,repository,author`
- PRs commented: `gh search prs --commenter USER --owner LiveViewTech --created 'START..END' --limit 1000 --json number,repository,author`

Derivations (apply the filters — the raw `gh` output does not):
- **Repo breadth:** distinct `repository`.
- **PRs commented (non-authored):** drop rows where `author == USER` (people comment on their own PRs); report the filtered count, not the raw one.
- **Distinct engineers reviewed:** distinct `author`, **excluding** `USER` (self) and bots (`*[bot]`, `Copilot`, `dependabot`, `github-actions`, `lvt-bot`). This metric is a human-influence signal — unfiltered bot/self counts inflate it.
- **Top repos by review count:** group reviewed PRs by `repository`.

GitHub search caps at ~1000 results; if a count hits the limit, note it as a floor (≥N) rather than exact.

## Jira / Confluence mining (Atlassian MCP)

- Epics / initiatives: `searchJiraIssuesUsingJql` with JQL like `(assignee = "ACCOUNTID" OR reporter = "ACCOUNTID") AND issuetype in (Epic, Initiative) AND updated >= "YYYY-MM-DD"`. Distinguish **owned** (assignee) from **self-filed** (reporter == them) — both matter; self-filed is the stronger signal.
- Self-filed initiatives are a strong P4b+ signal (work that's initiated, not assigned) — surface `reporter = "ACCOUNTID" AND issuetype = Initiative`.
- Postmortems: search Confluence (`searchConfluenceUsingCql`) for incident/postmortem pages authored by or attributed to the person; capture page IDs and the incident date.

## Dimensions that are tool-invisible (always require manager input)

These rarely appear in GitHub/Jira and must be requested at the evidence checkpoint:
- Cross-team adoption of the person's review/design/postmortem practices.
- Mentoring of *senior* engineers (vs. junior), and being sought by name across teams.
- Recruiting / hiring-committee / interview-loop leverage.
- Slack influence (threads where they unblocked or drove other teams).
- Lucid design docs and their approval/attribution (e.g., Architecture team sign-off).

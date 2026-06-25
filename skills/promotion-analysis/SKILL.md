---
name: promotion-analysis
description: Use when building a promotion case, leveling/readiness assessment, or career-ladder gap analysis for an engineer — mining their GitHub and Jira/Confluence activity, scoring it against the LiveViewTech career ladder, and producing committee-ready docs.
---

# Promotion & Leveling Analysis

## Overview

Produces evidence-backed promotion and leveling documents for a single engineer by mining tool data (GitHub, Jira/Confluence), scoring it against the LiveViewTech career ladder, and writing committee-ready markdown. The career ladder is a matrix — levels P1–P6 (with P4a/P4b) as columns, dimensions as rows — so any target level is just a column selection.

**The meets-the-bar verdict per dimension is a human judgment call, not a mechanical output.** This skill gathers and structures the evidence and proposes verdicts; the manager confirms or adjusts them at a checkpoint before any document is generated.

## Modes

Pick one per person at the start:

- **promotion case** — building an active case to promote *to* the target level. Produces three docs: full dossier + one-page committee summary + gap analysis for the level *beyond* the target (the development runway).
- **readiness assessment** — assessing where someone stands at their current/target level. Produces one standing assessment + a development plan (gap analysis to the target level). No committee one-pager.

## Prerequisites

| Dependency | Used for | Notes |
|------------|----------|-------|
| `gh` CLI (login `newellista`, scopes repo/read:org) | GitHub PR mining | `gh auth status` to confirm |
| Atlassian MCP (`mcp__atlassian__*`) | Jira/Confluence mining | Site `liveviewtech.atlassian.net`, project `JET` |
| `pdftotext` (poppler) | Reading the career ladder + hiring JD PDFs | Ladder is auth-gated in Google Drive MCP — must use local PDF |

**REQUIRED READING before Phase 1:** `references/access-and-data-sources.md` — file paths, identifiers, and access quirks (Slack/Lucid connectors do NOT work in the CLI; the ladder lives in a local PDF; a duplicate Jira account trap). Do not rediscover these the hard way.

## Two mandatory human checkpoints

This skill PAUSES twice and waits for the manager. Do not skip ahead.

1. **Evidence checkpoint (end of Phase 4)** — after tool-mining, present a tailored list of the evidence that tools cannot reach for this person/level. Wait for the manager to supply or explicitly waive each item before drafting.
2. **Verdict review (end of Phase 5)** — present the proposed per-dimension verdicts. Wait for the manager to confirm or adjust before generating any document.

## Workflow

### Phase 1 — Inputs & identifiers
Collect: full name, GitHub username, work email / Jira accountId, **current level**, **target level**, evidence window (default: trailing 12 months from today), and **mode**. Resolve the Jira accountId from the work email; if two accounts share the name, use the one *with* the email (see reference doc).

### Phase 2 — Load the bar
`pdftotext -layout` the career ladder PDF. Extract:
- the **target-level** column (the bar being assessed),
- the **current-level** column (to frame the "defining shift"),
- for `promotion case` mode only: the **level-beyond-target** column (for the gap analysis).

Pull every dimension row (Summary, Scope & Influence, Technical Contributions & Execution, Complexity, Leadership, Collaboration, …). If a hiring JD PDF exists for the target level, read it for the benchmark-vs-external-hire table.

### Phase 3 — Mine tool evidence
- **GitHub** (`gh`): PRs authored / reviewed / commented within the window, repo breadth, distinct engineers reviewed. See reference doc for query recipes.
- **Jira/Confluence** (Atlassian MCP): epics owned, initiatives self-filed, postmortems owned/driven, ownership signals.

Record concrete artifacts (PR counts + repos, Jira IDs, dates, links) — every claim in the final docs must trace to one.

### Phase 4 — Evidence checkpoint (PAUSE)
Map mined evidence onto the target level's dimensions. Flag dimensions that are thin or **tool-invisible**: Slack influence, Lucid design docs, cross-team adoption of the person's practices, mentoring of *senior* engineers, recruiting/hiring leverage. Present a dimension-by-dimension request list to the manager: for each affected dimension, state what tools confirmed (with numbers) and what specific evidence is still needed, naming the source (Slack thread, Lucid link, etc.). **Wait.**

### Phase 5 — Score & verdict review (PAUSE)
Assign a proposed verdict per dimension against the target level: ✅ **Met**, ✅ **Exceeds**, 🟡 **Partial**, 🔴 **Not evidenced**. Present the scorecard. **Wait** for the manager to confirm/adjust.

### Phase 6 — Generate deliverables
Fill the templates in `templates/` with the confirmed verdicts and evidence. Write markdown only (PDF declined) to `~/Documents/<PersonName>/`.

| Mode | Files |
|------|-------|
| promotion case | `<name>-<target>-promotion-case.md`, `<name>-<target>-promotion-summary.md`, `<name>-<beyond>-gap-analysis.md` |
| readiness assessment | `<name>-<target>-readiness.md`, `<name>-<target>-development-plan.md` |

Templates: `templates/promotion-case.md`, `templates/promotion-summary.md`, `templates/gap-analysis.md` (the gap-analysis template also serves the readiness + development-plan outputs).

## Common mistakes

- **Skipping a checkpoint.** Drafting before the manager supplies manual evidence, or before verdicts are confirmed, produces a doc built on tool data alone — exactly the evidence that's weakest at senior levels.
- **Asserting tool-invisible claims.** Never state cross-team influence, mentoring, or design-doc impact unless the manager supplied it. Mark it 🔴 Not evidenced otherwise.
- **Hardcoding the ladder.** Always read the PDF live — it is versioned and updates.
- **Wrong Jira account.** The duplicate-name account has no email; using it returns empty results.
- **Auto-scoring.** Do not finalize verdicts without the manager. The skill proposes; the manager decides.

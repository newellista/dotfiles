---
name: performance-evaluation
description: Use when preparing manager performance-review / calibration prep for engineers — filling the LVT calibration prep guide, mining GitHub and Jira/Confluence for evidence, and proposing a level-relative rating (Underperforming / Achieving Most Results / Achieving Results / Exceptional) for one or a batch of direct reports.
---

# Performance Evaluation & Calibration Prep

## Overview

Produces evidence-backed calibration prep documents for one or more engineers by mining tool data (GitHub, Jira/Confluence), scoring it against the LiveViewTech career ladder, and filling the LVT Calibration Prep Guide. Ratings are **relative to the person's current level** — the same output at P3 and P5 earns different ratings.

**Tool data can responsibly fill only part of this form.** GitHub/Jira give strong evidence for *Core Contributions* (§1) and *Quality & Impact* (§2), and a partial signal for *Collaboration* (§4). *Ownership & Initiative* (§3), *Growth & Development* (§5), and the *Calibration Talking Points* (§6) are things only the manager observed — they leave almost no trace in tools. This skill mines what tools can see, drafts those sections, proposes an **evidence-limited draft rating**, then hard-stops for the manager to supply the human-observed sections before anything is finalized. **The skill proposes; the manager decides and defends the rating in the room.**

## The rating scale (relative to level)

| # | Rating | Bar |
|---|--------|-----|
| 1 | Underperforming | Does not meet role expectations in one or more critical areas. |
| 2 | Achieving Most Results | Generally effective; meets most expectations with some gaps. |
| 3 | Achieving Results | Consistently meets expectations for the role **and level**. |
| 4 | Exceptional | Significantly exceeds expectations; sustained high impact. |

## Prerequisites

| Dependency | Used for | Notes |
|------------|----------|-------|
| `gh` CLI (login `newellista`, scopes repo/read:org) | GitHub PR mining | `gh auth status` to confirm |
| Atlassian MCP (`mcp__atlassian__*`) | Jira/Confluence mining | Site `liveviewtech.atlassian.net`, project `JET` |
| `pdftotext` (poppler) | Reading the career ladder + the calibration prep form | Both are auth-gated in Drive MCP — use local PDFs |

**REQUIRED READING before Phase 1:** `references/data-sources-and-mapping.md` — the form-section → data-source map, the fixed evidence window, and (by reference) the GitHub/Jira mining recipes and access quirks shared with `promotion-analysis`. Do not rediscover these the hard way.

## Two mandatory human checkpoints (per person)

This skill PAUSES twice for each employee. Do not skip ahead, and do not let batch speed collapse these into a rubber-stamp.

1. **Evidence checkpoint** — after tool-mining, present what tools found mapped to the six sections, plus a tailored request list for the tool-invisible sections. Wait for the manager to supply or explicitly waive each item.
2. **Rating review** — present the proposed level-relative rating (1–4), its one-sentence rationale, and the "why not one above or below" justification the form demands. Wait for the manager to confirm or adjust before generating the document.

## Workflow

### Phase 1 — Inputs & roster
Collect the employee list. Per person: full name, **GitHub handle**, **current level**, and work email (needed to resolve the Jira accountId). Also collect: the **review period** (default: H1 2026 = closed range `2026-01-01..2026-06-30`), and the **calibration prep form PDF** (default: newest `*Calibration Prep*Individual Contributor*.pdf` in `~/Downloads` — re-check for a newer version each cycle).

Resolve each person's Jira accountId from their work email via `mcp__atlassian__lookupJiraAccountId`. **Duplicate-account trap:** use the account *with* the email; the nameless duplicate returns empty activity.

### Phase 2 — Load the bar & the form
- `pdftotext -layout` the **career ladder** PDF. For each distinct level in the roster, extract that level's column — the rating is relative to it, and §1 asks whether scope was at-/below-/above-level.
- `pdftotext -layout` the **calibration prep form** PDF and re-confirm the section set. The form is versioned; do not hardcode the six sections from memory.

### Phase 3 — Mine tool evidence (batch, parallel)
Mine **every employee up front** before reviewing anyone (for a large roster, dispatch parallel agents — one per person). Per person, within the closed window:
- **GitHub** (`gh`): PRs authored / reviewed / commented, repo breadth, distinct engineers reviewed (filter bots + self).
- **Jira/Confluence**: epics owned (assignee) vs. self-filed (reporter), postmortems owned/driven.

Record concrete artifacts (PR counts + repos, Jira IDs, dates, links). Map them onto §1, §2, and the reachable part of §4. See the reference doc for exact recipes.

### Phase 4 — Per-employee evidence checkpoint (PAUSE, looped)
Now walk the roster one person at a time. For each: present the tool findings mapped to the six sections, then request the tool-invisible evidence — §3 proactive risk-surfacing and follow-through, §4 communication quality, §5 growth trajectory / promotion path / timeline, §6 how you'd describe them to peers + any context factors (role/team/scope changes, personal circumstances). **Wait** before drafting that person.

### Phase 5 — Rating review (PAUSE, per person)
Propose a level-relative rating (1–4) with the one-sentence rationale and the "not one above/below" justification. Present. **Wait** for confirm/adjust.

### Phase 6 — Generate deliverables
Fill `templates/calibration-prep.md` per person with confirmed evidence (cited inline) and the confirmed rating. Add/update that person's row in `templates/calibration-roster.md`. Write markdown to `~/Documents/Calibration/<period>/`:

| Artifact | File |
|----------|------|
| Per-employee filled form | `<name>-calibration-prep.md` |
| Team calibration roster | `roster.md` (one row per employee) |

These are **confidential** performance documents. Keep them under `~/Documents/Calibration/`; do not paste contents into external services.

### Phase 7 — Editorial review pass (per person, after the manager edits)
After the manager fills in or edits a person's doc, review it for **content, grammar, and tone** before it is final — it is going into the calibration room, so leftover scaffolding or contradictions read as unfinished. Check for:
- **Leftover scaffolding.** Delete any `[MANAGER INPUT PENDING]`, `(Draft from tools…)`, or instruction-to-manager prompts still in the prose.
- **Internal contradictions.** Two different growth areas, a rating rationale citing evidence the manager removed, a "candidate growth area" the manager's notes contradict.
- **Rating consistency.** Does the filled evidence still support the confirmed rating and its "why not above/below"? Reconcile the roster row to match.
- **Quality over quantity.** No section should *lead* with PR/review counts — lead with specific review catches, owned outcomes, and impact; counts are supporting context only.
- **Surface the strongest evidence.** Make sure the hardest quantified outcome (e.g., "½ of clients migrated") appears in §6 "strongest evidence," not buried in §1/§2.
- **Grammar / mechanics.** Typos, tense, hyphenation, blockquote/formatting consistency.

Present findings grouped as content / grammar / tone; apply on the manager's go. Watch for the manager re-introducing count-first framing on edit — quietly reframe it.

### Phase 8 — Workday transcription (downstream, when asked)
After the calibration docs are final, the manager transcribes ratings into Workday. The IC review has **two free-text prompts** beyond the 1–4 rating:
- **Key Achievements** — Business Impact · Values in Action · Above and Beyond
- **Misses & Challenges** — Business Impact · Team Burden · Additional Oversight · Values Gaps

Produce one `<name>-workday-review.md` per person (same dir as the calibrations) answering both, synthesized from that person's calibration doc. Map behaviors to the **LVT Values** (`references/` / `lvt.com/about`; also in auto-memory): **Be the Crew · Own It · Chew the Strap · Do Right · Pursue Excellence**.

- **Do NOT fabricate misses.** Calibration docs are rating-*defense* and skew to strengths. For Misses & Challenges, surface genuine growth-edges and state "no delivery misses" where that's true; flag `[MANAGER: confirm]` for anything only the manager would know. Warn the manager that an all-positive Misses section across a team may draw calibrator questions.
- **Format:** deliver the per-person markdown; the manager pastes into Workday directly. RTF is **not** part of the flow (confirmed H1 2026 — don't generate it by default). If a rich-text file is ever explicitly requested, `scripts/md-to-rtf.sh <dir-or-files>` converts md→RTF via macOS `textutil`.

## Common mistakes

- **Rating on tool data alone.** §3/§5/§6 are mostly tool-invisible. A rating that ignores them is indefensible in calibration.
- **Skipping / rubber-stamping a checkpoint.** Batch mining is fast; the per-person review is not meant to be. Both pauses happen for every employee.
- **Asserting tool-invisible claims.** Never state proactive risk-surfacing, collaboration quality, or growth trajectory unless the manager supplied it. Mark it as manager-input-pending otherwise.
- **Rating without level context.** "Achieving Results" means meeting the bar *for that level*. Load the ladder column first.
- **Wrong Jira account** (the nameless duplicate) or an **open-ended window** (`>=START` over-counts) — use the email-bearing account and a closed `START..END` range.
- **Hardcoding the ladder or form.** Both are versioned — read the PDFs live each cycle.
- **Leading with PR/review counts.** Volume is a *secondary* signal and invites the "were those real reviews or rubber-stamps?" challenge. Lead with review *quality* — specific catches that changed code before merge (dig the review threads to find them) — and owned outcomes; keep counts as supporting context. Applies to drafting and to the Phase 7 review.
- **Skipping the editorial pass.** A doc full of `[MANAGER INPUT PENDING]` flags or count-first framing is not calibration-ready. Run Phase 7 on every person's doc after the manager edits it.

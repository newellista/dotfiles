# Data Sources & Form-Section Mapping

Read before Phase 1. Covers what's specific to performance-evaluation; the shared GitHub/Jira mining recipes and access quirks live in the `promotion-analysis` skill and are referenced below (same org, same tools — do not fork them).

## Shared access quirks & mining recipes (do not duplicate)

The GitHub `gh` search recipes, the Jira JQL patterns, the accountId lookup, the duplicate-account trap, the bot/self filters for "distinct engineers reviewed," the ~1000-result cap, and the career-ladder PDF path all live in:

`~/.claude/skills/promotion-analysis/references/access-and-data-sources.md`

Read that file for the exact commands. The only differences for performance-evaluation:
- **Evidence window is a fixed, closed range**, not trailing-12-months. Default H1 2026 = `2026-01-01..2026-06-30`. Always use a closed `START..END` range — `>=START` over-counts.
- **The calibration prep form PDF** is an additional local PDF to read (see below). It is versioned like the ladder.

## The calibration prep form PDF

Default location: newest file matching `*Calibration Prep*Individual Contributor*.pdf` in `~/Downloads`
(e.g. `H1 2026 Calibration Prep — Individual Contributor.docx - Google Docs.pdf`).

Read with `pdftotext -layout "<path>" -`. Re-confirm the section set each cycle; the form is versioned and section wording/order can change. As of H1 2026 the sections are:

1. **Core Contributions** — ownership vs. participation; scope/complexity relative to level (at-/below-/above-level).
2. **Quality and Impact of Output** — specific evidence for the rating; where they raised the bar.
3. **Ownership and Initiative** — followed through past assignment; surfaced risks/blockers proactively.
4. **Collaboration and Cross-Functional Work** — worked effectively with peers/partner teams; communicated progress/tradeoffs/blockers.
5. **Growth and Development** — position on path to next level (Early / Progressing / Ready / Not pursuing); primary growth area; promotion path + timeline.
6. **Calibration Talking Points** — 2–3 sentence peer description; the one thing the group should understand; strongest evidence; context factors.

Plus the header block (employee info) and the 1–4 rating with a one-sentence "why this and not one above/below" rationale.

## Form-section → data-source map

How much each section can be filled from tools vs. requires manager input at the evidence checkpoint:

| Section | Tool coverage | What tools give | What only the manager has |
|---------|---------------|-----------------|---------------------------|
| §1 Core Contributions | **Strong** | PRs authored (ownership), Jira epics owned (assignee) vs. participated; repo breadth; scope judged against the level column | Non-code ownership; whether "owned" reflects real accountability vs. assignment |
| §2 Quality & Impact | **Strong** | Merged PRs, postmortems owned/driven, review depth as a quality signal | "Raised the bar" for the team; downstream outcomes; incidents avoided |
| §3 Ownership & Initiative | **Weak** | Self-filed Jira initiatives/bugs = weak proactive signal | Proactive risk-surfacing, follow-through past the task, creating information flow |
| §4 Collaboration | **Partial** | PRs reviewed, distinct engineers reviewed (bots/self filtered) = collaboration surface | Communication quality, cross-team effectiveness, how others experience them |
| §5 Growth & Development | **Weak** | Ladder gap to next level (from `promotion-analysis` if a case exists) | Growth conversations, trajectory speed, promotion timeline, development plan |
| §6 Calibration Talking Points | **None** (synthesis) | — (synthesized from §1–§4 evidence) | Peer-facing description, the one key point, context factors, personal circumstances |

**Rule:** only §1, §2, and the reviewed-PR half of §4 may be asserted from tools. Everything else is drafted as *manager-input-pending* until supplied at the checkpoint, then rated.

## Rating is relative to level

Load the person's **current-level column** from the career ladder before proposing a rating. "Achieving Results" (3) = consistently meets the bar *for that level*. The same PR/epic volume that is Exceptional at P2 may be merely Achieving Results at P4. §1 explicitly asks whether scope was at-/below-/above-level — answer it against the column, not against the whole team.

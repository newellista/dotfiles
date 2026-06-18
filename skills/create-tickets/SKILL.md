---
name: create-tickets
description: >-
  Decomposes a finished implementation plan into tracking tickets. Detects
  whether to use GitHub issues (personal projects under ~/projects/personal/)
  or Jira tickets (work projects under ~/projects/). Creates tickets in
  dependency-ordered phases so issue numbers/keys can be referenced in later
  phases. For GitHub: creates a tracking/epic issue last. For Jira: attaches
  all tickets to an existing parent Epic or Story. Use when the user says
  "create tickets", "create issues", or "decompose plan to issues".
---

# Decompose Plan into Tickets

## Step 0 — Detect backend

Run `pwd` and apply this heuristic:

| Working directory | Backend |
|-------------------|---------|
| Matches `~/projects/personal/*` | **GitHub** — use `gh issue create` |
| Matches `~/projects/*` (any other) | **Jira** — use Atlassian MCP tools |

Do not proceed until you know which backend to use.

## Mandatory order (both backends)

1. **Read the plan file.**
2. **Build the dependency map** — identify atomic units, dependencies, phases.
3. **Resolve the parent** (Jira only) — see Jira section below.
4. **Create Phase 1 tickets first** (no cross-dependencies). Capture each
   identifier (GitHub issue number or Jira key) immediately.
5. **Create Phase 2+ tickets**, referencing earlier identifiers in dependency
   fields. Repeat per phase.
6. **Create tracking ticket last** (GitHub only — see below).

---

## GitHub Backend

### Issue title format

```
[Feature] Phase N — Component: what changes
```

### Issue body format

```markdown
## Summary

[1–2 sentences: what changes and why.]

**Depends on:** #N, #M   ← omit if no dependencies

## File(s)

[Exact paths of every file to create or modify.]

## Changes

[Exact code patterns in the project's language — real snippets, not pseudocode.
Show the function signature, struct field, clause to add, etc.]

## Tests

[What to add or update. Name the test file and describe cases by behaviour.]

## Acceptance Criteria

- [ ] [Specific, verifiable item]
- [ ] [e.g. "MIX_TARGET=host mix test green"]

## Part of

[Feature name] — tracking issue: #N
```

### Tracking/epic issue (GitHub — created last)

Title: `[Feature] Epic — Feature Name`

```markdown
## Overview

[2–3 sentences on the feature and outcome.]

## Dependency graph

```
Phase 1 (parallel):
  #N  Description
  #N  Description

Phase 2 (depends on Phase 1):
  #N  Description  ← depends on #A, #B
```

## Checklist

### Phase 1
- [ ] #N Description

### Phase 2
- [ ] #N Description

## Verification

[End-to-end steps: test command, compile targets, manual smoke test.]
```

---

## Jira Backend

### Step 0 — Resolve parent

Before creating any tickets, find the existing Epic or Story that will be
the parent. Try in order:

1. Ask the user: "What is the Jira key of the parent Epic or Story for this
   work?" (e.g. `JET-123`)
2. If the user gives a key, call `mcp__atlassian__getJiraIssue` to confirm
   it exists and note its summary.

All new tickets will be linked to this parent.

### Issue type

Use **Story** (the default per CLAUDE.md) unless the parent is itself a
Story, in which case use **Sub-task**.

### Ticket format

**Summary (title):** `[Phase N] Component: what changes`
(No `[Feature]` prefix — that context comes from the parent.)

**Description:** Same content as the GitHub body format above, adapted for
Jira markdown (use `*bold*`, `{code}` blocks, etc.).

**Create call:** `mcp__atlassian__createJiraIssue` with:
- `projectKey`: from CLAUDE.md (`JET` by default; confirm if repo differs)
- `issueType`: Story (or Sub-task)
- `summary`: as above
- `description`: formatted body

After creating each ticket, call `mcp__atlassian__createIssueLink` to attach
it to the parent:
- `inwardIssueKey`: new ticket key
- `outwardIssueKey`: parent key
- `linkType`: `"Child of"` (or `"is child of"` — call
  `mcp__atlassian__getIssueLinkTypes` once at the start to confirm the
  exact name)

### Dependency links between tickets

For "depends on" relationships between tickets in the same feature, use
`mcp__atlassian__createIssueLink` after both tickets exist:
- `linkType`: `"Blocks"` (the Phase 1 ticket blocks the Phase 2 ticket that
  depends on it — `inward: Phase1Key blocks outward: Phase2Key`)
- Call `getIssueLinkTypes` once to confirm exact link type names for this instance.

### No separate tracking ticket for Jira

The existing parent Epic/Story serves as the tracking issue. After all
tickets are created, add a comment to the parent via
`mcp__atlassian__addCommentToJiraIssue` with:
- A brief summary of what was created
- A list of the new ticket keys with one-line descriptions

---

## Red flags (both backends)

**Never:**
- Create a Phase 2 ticket before all Phase 1 tickets exist
- Create the GitHub tracking issue before all sub-issues exist
- Use guessed/approximate ticket numbers or keys — always use real values
  captured from create calls
- Skip `getIssueLinkTypes` on the Jira path — link type names vary by instance

**Always:**
- Capture the identifier (issue number or Jira key) returned by each create call
- Include dependency links only for real blocking dependencies
- Write code snippets in the actual project language, not pseudocode

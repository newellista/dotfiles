---
name: soc2-audit
description: Use when performing the monthly SOC 2 compliance log audit
---

# SOC 2 Monthly Log Audit

## Overview

Automates the monthly SOC 2 compliance log review. Queries Coralogix for the prior calendar month, compares against the month before as a dynamic baseline, categorizes errors, and updates Jira tickets with findings.

## Prerequisites

**Required MCP servers** — the skill will fail at Steps 2, 3, 6, and 7 without these:

| MCP Server | Used for | Install |
|------------|----------|---------|
| Atlassian MCP (`mcp__atlassian__*`) | Finding Jira tickets, posting comments, closing tickets | Remote server — no local install. [Setup docs](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/setting-up-ides/) or add via `npx -y mcp-remote@latest https://mcp.atlassian.com/v1/mcp/authv2` (Node 18+ required) |
| Coralogix MCP (`mcp__coralogix__*`) | Querying log data | Remote server — `claude mcp add coralogix-server --transport http https://api.<region>.coralogix.com/mgmt/api/v1/mcp --header "Authorization: Bearer <API-KEY>"`. [Setup docs](https://coralogix.com/docs/user-guides/mcp-server/setup/) |

If you don't have these configured, dry-run mode will still fail at Step 2. Install and authenticate both servers before running this skill.

**Required org-specific setup** — the Configuration section and Service Map below contain values specific to one organization. You must replace all of them before the skill will work for you.

---

## Modes

- **Normal** (`/soc2-audit`): run full analysis, post comment to Jira, transition ticket to Done (or leave open if anomalous).
- **Dry run** (`/soc2-audit dry-run`): run full analysis and print results to the conversation. Do **not** post any Jira comment or transition any ticket.

**Announce at start:** "Running soc2-audit skill [dry-run] to perform the monthly SOC 2 log review." (include `[dry-run]` in dry-run mode)

## Configuration

> **You must replace every value in this section before sharing or running this skill.** All values below are org-specific — none are defaults.

| Setting | Value | Notes |
|---------|-------|-------|
| Jira Cloud ID | `liveviewtech.atlassian.net` | Your Atlassian subdomain |
| Jira project key | `JET` | Your Jira project key |
| Ticket summary pattern | `"Log Auditing for SOC 2 Compliance"` | Must match your ticket naming convention |
| Done transition ID | `101` | Instance-specific — run `mcp__atlassian__getTransitionsForJiraIssue` on any ticket to find yours |

## Service Map

> **Replace all rows below with your own services.** The rows shown are examples from one organization and will not match your Coralogix setup. The production filter field (used to exclude staging/dev traffic) differs per service — sample a few raw log records first if you're unsure which field and value identify production traffic.

| Jira ticket suffix   | applicationname | subsystemname    | Production filter                                               | Severity field |
|----------------------|-----------------|------------------|-----------------------------------------------------------------|----------------|
| partner-nodejs-api   | backend         | lvt-api          | `$d.resource.attributes.k8s_cluster_name == 'production'`       | `$m.severity` |
| lv-userdashboard     | frontend        | lv-userdashboard | `$d.environment == 'prd'`                                       | **`$d.level:string`** — see below |

### ⚠️ `lv-userdashboard` prd: do NOT audit on `$m.severity`

Its prd traffic is Firehose-ingested (`computername: firehose`) and Coralogix never derives severity from the app's `level` field. `$m.severity` reports **zero** `Error` and **zero** `Critical` — always — against 100k+ real errors a month. Auditing this service on `$m.severity` returns a **false CLEAN**. Tracked as **JET-74528**; until that lands, audit on `$d.level:string` and use the level values `INFO` / `WARN` / `ERROR`.

The observed collapse: app `INFO` → Coralogix `Verbose`; app `WARN` **and** `ERROR` → Coralogix `Info`.

Two general lessons for adding services to this map:

- **Never trust a zero.** A production service reporting zero errors is a broken query or a broken pipeline until proven otherwise. Verify a service's severity field before its first audit: `groupby $m.severity` and `groupby $d.level:string` should agree.
- **Staging looking noisier than production is a red flag, not good news.** `stg`/`int` ingest by a different path and map severity correctly, which is exactly what made this defect easy to miss.

Cross-check source: CloudWatch log group `/lv-userdashboard` in **lvt-infrastructure-prd (817432301776)**, us-west-2, 120-day retention. It holds the same records with severity intact and is unaffected by this bug. Needs the `EngineeringUser` SSO role.

## Step-by-Step Workflow

### 1. Calculate date ranges

- **Review period:** previous calendar month (e.g. running in May → April 1–May 1)
- **Baseline period:** two months ago (e.g. running in May → March 1–April 1)

### 2. Find open tickets

First, look up the current user's email with `mcp__atlassian__atlassianUserInfo` (use the `emailAddress` field from the result as `<ASSIGNEE_EMAIL>`).

Then use `mcp__atlassian__searchJiraIssuesUsingJql` with the Cloud ID, project key, and ticket summary pattern from the Configuration section above:

```
project = <PROJECT_KEY>
AND summary ~ "<TICKET_SUMMARY_PATTERN>"
AND assignee = "<ASSIGNEE_EMAIL>"
AND status != Done
AND created >= startOfMonth()
```

### 3. For each ticket — query Coralogix severity breakdown

Run this query twice: once for the review period, once for the baseline period.

```dataprime
source logs
| filter $l.applicationname == '<APP>'
| filter $l.subsystemname == '<SUBSYSTEM>'
| filter <PROD_FILTER>
| groupby <SEVERITY_FIELD> aggregate count() as cnt
| orderby cnt desc
```

Use the production filter and **severity field** from the Service Map table above. For services on `$d.level:string`, alias it: `groupby $d.level:string as lvl aggregate count() as cnt`.

Tool: `mcp__coralogix__query_dataprime`, tier: `TIER_ARCHIVE`

**Valid severity values:** `VERBOSE`, `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL` (use these exact values — quoted string values like `'Error'` are deprecated and may cause warnings). Application `level` values are different: `INFO`, `WARN`, `ERROR`.

A month-wide aggregation over `TIER_ARCHIVE` will often time out inline. Use `mcp__coralogix__submit_background_query`, then poll `get_background_query_status` and fetch with `get_background_query_data`. An empty result means zero matches — a `groupby` with no rows returns no records.

### 4. Sample error logs for categorization

**Do not sample.** Earlier versions of this skill said `groupby $d.message` is unsupported and told you to pull `limit 500` and count locally. That is wrong on both counts, and the sampling produces materially false numbers — see the warning below.

`groupby` on a `$d` field works if you add a **typed accessor** and an alias:

```dataprime
source logs
| filter $l.applicationname == '<APP>'
| filter $l.subsystemname == '<SUBSYSTEM>'
| filter <PROD_FILTER>
| filter <SEVERITY_FIELD> == <ERROR_VALUE>
| groupby $d.message:string as msg aggregate count() as cnt
| orderby cnt desc
| limit 30
```

This returns **full-population counts**. Submit it as a background query (month-wide archive aggregations time out inline). Repeat for Critical.

> ### ⚠️ Why `limit N` is not a sample
>
> `limit 500` returns whichever 500 records the engine reaches first — not a random draw. In the July 2026 audit it put one error category at 6% of the total when the true share was **36.8%**, and it mis-attributed a category's dominant client because that client's per-entity message variants happened to fill the visible rows. Both errors reached a compliance record before being caught. Never characterize an error mix from a `limit N` pull.

**When messages embed IDs.** If per-entity IDs make each message unique (`... for LU 19967 ...`), the raw `groupby` fragments into a long tail and understates the category. Aggregate with `contains()` on the stable prefix instead:

```dataprime
| filter $d.message:string.contains('<stable substring>')
| groupby $l.subsystemname aggregate count() as cnt
```

Or extract the varying part and group on it:

```dataprime
| extract $d.message:string into parsed using regexp(e=/client (?<cid>\d+)/)
| groupby parsed.cid:string as cid aggregate count() as cnt
```

Cross-check that your categories sum to the severity total from Step 3. If they do not, you are missing a long tail.

Group errors into 4–6 human-readable categories. List all Critical categories (there should be few). If Critical count is 0, omit the Critical Categories section from the comment.

**Nested and reserved keys.** Use the full path (`$d.logData.error_msg`, not `$d.error_msg`) — a wrong path yields a *compile warning*, not an error, and silently matches nothing. `level` is reserved: `$d.level`, `$d['level']`, and `$d.'level'` all fail; only `$d.level:string` works.

### 5. Analyze

Flag as **anomalous** if:
- Error or Critical count is >20% higher than baseline month
- New error message categories appear with significant volume — check onset and end dates by narrowing the window, and confirm whether a Jira bug or Rootly incident was ever filed. **An untracked production incident is itself a finding** (SOC 2 CC7.2/CC7.3), separate from whatever caused it
- A severity or level that should be present reports **zero**, or a category's composition shifts materially while the total stays flat

Flag as **clean** if counts are stable and error categories are consistent with prior months.

A stable total can hide a large new category offset by a decline elsewhere — compare composition, not just totals.

### 6. Post Jira comment (skip in dry-run mode — print to conversation instead)

In **dry-run mode**, render the report below as a markdown code block in the conversation and stop — do not call any Jira tools.

In **normal mode**, use `mcp__atlassian__addCommentToJiraIssue` with this markdown template:

```markdown
## SOC 2 Log Audit — <Month> <Year>

**Review period:** <start> – <end>
**Log source:** Coralogix (<applicationname> / <subsystemname>)

---

### Severity Breakdown

| Severity | <Review month> | <Baseline month> | Change |
|----------|----------------|------------------|--------|
| Verbose  | N              | N                | ±X%    |
| Info     | N              | N                | ±X%    |
| Debug    | N              | N                | ±X%    |
| Warning  | N              | N                | ±X%    |
| Error    | N              | N                | ±X%    |
| Critical | N              | N                | ±X%    |

### Error Categories (all N records, not sampled)

| Category | Count | Share |
|----------|-------|-------|
| ...      | N     | N%    |

### Critical Categories (all records)

| Category | Count | Share |
|----------|-------|-------|
| ...      | N     | N%    |

### Verdict: ✅ CLEAN  (or ⚠️ NEEDS REVIEW)

<1-2 sentence summary of findings>
```

### 7. Transition ticket (skip in dry-run mode)

If clean: use `mcp__atlassian__transitionJiraIssue` with `transitionId: "101"` (Done).

If anomalous: leave open. Prepend `[NEEDS REVIEW]` to the comment verdict section.

## Common Mistakes

- **Trusting a zero**: a production service reporting zero errors is a broken query or a broken pipeline until proven otherwise. Never issue a CLEAN verdict off a zero you have not corroborated against a second field or source
- **Auditing the wrong severity field**: check the Service Map's Severity field column. `lv-userdashboard` prd *must* use `$d.level:string`; `$m.severity` returns a false CLEAN there
- **Sampling with `limit N`**: it is not a random sample and will misstate category shares — use `groupby $d.message:string as msg` for full-population counts
- **Wrong severity string**: use `ERROR` not `'Error'` in DataPrime filter. App `level` values are `INFO`/`WARN`/`ERROR`, which are not the same set as Coralogix severities
- **Wrong tier**: always use `TIER_ARCHIVE` for prior-month data — frequent search tier won't have it
- **Bare `$d` fields in groupby/filter**: add the typed accessor (`$d.field:string`, `$d.field:number`). Bare `$d.message` and `$d.level` both fail
- **Wrong nested path**: returns a compile *warning* and silently matches nothing, not an error. Verify the full path against a sample record
- **Inline month-wide aggregations**: they time out. Use `submit_background_query` and poll
- **Missing Critical rows**: if Critical count is 0 it won't appear in the groupby result — treat as 0
- **Review period confusion**: "May Log Auditing" tickets are created May 1 and audit April's logs; always use the *previous* calendar month as the review period

## Quick Reference

| Action | Tool |
|--------|------|
| Find tickets | `mcp__atlassian__searchJiraIssuesUsingJql` |
| Query logs | `mcp__coralogix__query_dataprime` (TIER_ARCHIVE) |
| Post comment | `mcp__atlassian__addCommentToJiraIssue` |
| Close ticket | `mcp__atlassian__transitionJiraIssue` transitionId `"101"` |
| Get current user | `mcp__atlassian__atlassianUserInfo` |
| Cloud ID | see Configuration section |

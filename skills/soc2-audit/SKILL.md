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

| Jira ticket suffix   | applicationname | subsystemname    | Production filter                                               |
|----------------------|-----------------|------------------|-----------------------------------------------------------------|
| partner-nodejs-api   | backend         | lvt-api          | `$d.resource.attributes.k8s_cluster_name == 'production'`       |
| lv-userdashboard     | frontend        | lv-userdashboard | `$d.environment == 'prd'`                                       |

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
| groupby $m.severity aggregate count() as cnt
| orderby cnt desc
```

Use the production filter from the Service Map table above for `<PROD_FILTER>`.

Tool: `mcp__coralogix__query_dataprime`, tier: `TIER_ARCHIVE`

**Valid severity values:** `VERBOSE`, `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL` (use these exact values — quoted string values like `'Error'` are deprecated and may cause warnings)

### 4. Sample error logs for categorization

`groupby $d.message` is NOT supported in this Coralogix setup. Instead, pull a sample and group locally:

**Error sample** (limit 500):

```dataprime
source logs
| filter $l.applicationname == '<APP>'
| filter $l.subsystemname == '<SUBSYSTEM>'
| filter <PROD_FILTER>
| filter $m.severity == ERROR
| limit 500
```

**Critical — fetch all** (no limit; Critical counts are typically small):

```dataprime
source logs
| filter $l.applicationname == '<APP>'
| filter $l.subsystemname == '<SUBSYSTEM>'
| filter <PROD_FILTER>
| filter $m.severity == CRITICAL
```

Save each output to a separate file. Then extract and count message fields with Python (run once per file):

```python
import re
from collections import Counter

with open('<saved-output-file>') as f:
    text = f.read()

messages = re.findall(r'"message": "([^"]+)"', text)

def normalize(m):
    import re
    m = re.sub(r'\(id: \d+\)', '(id: N)', m)
    m = re.sub(r'[0-9a-f]{8}-[0-9a-f-]{27}', 'UUID', m)
    return m

c = Counter(normalize(m) for m in messages)
for msg, cnt in c.most_common(15):
    print(f'{cnt:>6}  {msg[:100]}')
```

Group Error messages into 4–6 human-readable categories. List all Critical categories (there should be few). If Critical count is 0, omit the Critical Categories section from the comment.

### 5. Analyze

Flag as **anomalous** if:
- Error or Critical count is >20% higher than baseline month
- New error message categories appear with significant volume

Flag as **clean** if counts are stable and error categories are consistent with prior months.

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

### Error Categories (sampled from 500 records)

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

- **Wrong severity string**: use `ERROR` not `'Error'` in DataPrime filter
- **Wrong tier**: always use `TIER_ARCHIVE` for prior-month data — frequent search tier won't have it
- **groupby on $d.message fails**: don't attempt it; use the sample + local Python approach above
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

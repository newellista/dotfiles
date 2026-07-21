---
name: coralogix-error-investigation
description: Use when a user shares an error report, alert, stack trace, or log excerpt, OR asks to triage the Coralogix daily error report / daily errors digest — fetches the digest from Gmail, sorts noise vs. investigate, finds related logs in Coralogix, identifies root cause, and determines whether an error is noise worth suppressing
---

# Coralogix Error Investigation

## Overview

Structured workflow for investigating errors using Coralogix MCP tools. Extract context from the error → query related logs → assess frequency and impact → recommend a fix or suppression strategy.

Two entry points:
- **Single error** (alert, stack trace, log excerpt) → go straight to Step 1 and run the deep flow.
- **Daily digest email with multiple errors** → run **Batch Triage** first to sort the list, then run the deep flow (Steps 1–5) only on the errors flagged `investigate`.

## Batch Triage (daily digest emails)

Use this phase for the Coralogix **"Daily Error Report"** email. Trigger phrases: "triage today's Coralogix report", "run the daily errors". The goal is a fast sort — not a full investigation of every line. Deep querying (Steps 1–5) happens only on the survivors.

**What this email is:** Coralogix's built-in **Error Tracking → "New Errors"** daily report — *not* an alert definition (the alert-management MCP endpoints are unavailable in this account's region anyway; do not try `list_alert_definitions`/`search_alerts`). Every entry is a **newly-appearing error signature**, so novelty is already given — do not spend queries proving an error is "new." Each entry embeds the full log record (with `k8s_cluster_name`, message, pod) plus a "View error" link.

### 1. Retrieve the digest (no copy-paste)

Fetch it directly with the Gmail MCP:

- Search: `mcp__claude_ai_Gmail__search_threads` with query `from:support@coralogix.com subject:"daily error report" newer_than:2d`. Take the newest thread. (Do **not** rely on `label:Label_7914977813822976558` — the label-ID search returns empty via this MCP even though the messages carry that label.)
- Fetch: `mcp__claude_ai_Gmail__get_thread` with `messageFormat: FULL_CONTENT`. The body is `htmlBody` only (~150K chars) — it exceeds the inline limit and is **saved to disk**. Parse the saved file, do not try to read it inline.

If Gmail returns "requires re-authorization", ask the user to reconnect via `/mcp`.

### 2. Parse the entries

Strip tags from `htmlBody` and pull each entry's app, subsystem, occurrence count, share %, embedded log JSON, and link. Working parser (the word is misspelled "ocurrences" in the email; keep `<td|tr|div|p|h|table>` as the only line-breaking tags — adding `span`/`a` splits the count from its label):

```python
import json,re,html
d=json.load(open(SAVED_FILE)); h=d["messages"][0]["htmlBody"]
txt=re.sub(r'(?is)<(script|style).*?</\1>',' ',h)
txt=re.sub(r'(?is)<br\s*/?>','\n',txt)
txt=re.sub(r'(?is)</(td|tr|div|p|h[1-6]|table)>','\n',txt)
txt=re.sub(r'(?is)<[^>]+>',' ',txt); txt=html.unescape(txt)
txt=re.sub(r'[ \t]+',' ',txt); lines=[l.strip() for l in txt.split('\n') if l.strip()]
for i,l in enumerate(lines):
    m=re.match(r'(\d+)\s+ocurrences',l)   # count line; next line has "X% of your errors."
    # the two non-JSON label lines just above are applicationname / subsystemname
```

The `%` denominator is total new-error occurrences that day; entries are ranked by share, top signatures only.

### 3. Environment filter — production only (per entry)

Read the environment from each embedded record — **do not infer from volume**:
- Backend logs: `resource.attributes.k8s_cluster_name`.
- RUM/browser logs (`subsystemname: cx_rum`): `cx_rum.environment`.

**Keep only production** (`production` / `prd`). **Drop everything else** — `integration`, `staging`, PR-preview pods (e.g. `*-preview-####`), etc. Non-production errors are out of scope; do not classify or enrich them. Report only a one-line count of what was excluded (no silent truncation), then proceed with the production entries.

### 4. Classify (from the email alone)

Production entries only (non-prod already dropped in step 3). Every entry is already new, so classify by **impact**, not novelty:

- **investigate** — plausibly user-impacting (5xx, data loss, auth/subscribe failure, crash), or a signature matching a known incident pattern.
- **noise** — expected condition logged at ERROR, bot/crawler failures, RUM noise (single-device longtasks).
- **uncertain** — can't tell from the record. Default here when unsure; resolve it with the enrichment query below rather than guessing.

### 5. Enrich the keepers (one query each)

For every `investigate` **and** `uncertain` entry, run **one** DataPrime query: is this signature **still happening in the last 24h, and at what rate** — the question the email can't answer (ongoing problem vs. one-off blip):

```
source logs | filter $l.subsystemname == '<subsystem>' && $d ~~ '<distinctive phrase>'
| groupby roundTime($m.timestamp, 1h) as hr aggregate count() as cnt | sortby hr asc
```

Ongoing/climbing in the most recent buckets → confirm `investigate`; a burst that already stopped → downgrade (note it, don't silently drop). A confirmed high ongoing rate **outranks a higher email occurrence count** — the "New Errors" ranking does not reflect whether an error is still firing. Confirmed `investigate` entries proceed to the deep flow (Steps 1–5); `uncertain` that survives is treated as `investigate`.

**`query_dataprime` wrapper gotchas (all verified — the query silently returns nothing or errors otherwise):**

| Gotcha | Rule |
|--------|------|
| Full-text match | Use the `~~` operator (`$d ~~ 'phrase'`). `text contains …` and `.contains()` are both **rejected**. |
| Tier | **Backend service logs are in `TIER_ARCHIVE`; RUM logs (`cx_rum`) are in `TIER_FREQUENT_SEARCH`.** Wrong tier returns empty — a false "no errors". Set `tier` explicitly per source. |
| Severity value | Data is **title-case** (`$m.severity == 'Error'` / `'Warning'`). The wrapper warns to use uppercase `ERROR`, but uppercase matches **zero rows**. |
| Time window | Always set `endDate` explicitly — an empty `endDate` clamps the window to ~15 minutes. |
| Short tokens | Tokens <4 bytes are not indexed (`~~ '503'` matches nothing) — use a longer distinctive phrase or an adjacent token. |
| String literals | Single quotes only — double quotes fail with "Invalid query or parameters". |
| Environment split | RUM has no `k8s_cluster_name`; group by `$d.cx_rum.environment` instead of `$d.resource.attributes.k8s_cluster_name`. |

### 6. Report

Produce the batch report (see Step 5 → Batch report format): a disposition table covering the **full** list, then a full investigation section per confirmed `investigate` entry.

## Step 1: Extract Error Context

Before querying, identify from the provided error:

| Field | Examples |
|-------|---------|
| Error type/class | `NullPointerException`, `ECONNREFUSED`, `HTTP 502` |
| Exact message text | Used verbatim in search |
| Service/app name | `applicationName` filter |
| Timestamp + timezone | Anchors the time window |
| Correlation IDs | `traceId`, `requestId`, `userId`, `sessionId` |
| Severity | `ERROR`, `FATAL`, `WARN` |

**If timestamp or service name is missing, ask before querying.** Time-scoped queries are dramatically more effective.

Check the `platform` attribute or `k8s_cluster_name` in the submitted error for environment signals (e.g. `production`, `staging`, `stage`, `dev`). If the environment is **not** production, stop and notify the user before proceeding:

> "This error appears to be from **[environment]**, not production. Do you want to continue the investigation?"

Wait for confirmation before querying.

**For daily reports with multiple errors:** check `k8s_cluster_name` on every error individually before classifying it. Do not infer environment from volume — high occurrence counts do not mean production. An integration error with 400K occurrences is still an integration error.

## Step 2: Query the Error

Use `mcp__coralogix__query_lucene` for text searches.

**Start with ±30 minutes around the error timestamp, then widen to 24 hours if needed.**

> **Field addressing note:** Coralogix stores labels (`applicationname`, `subsystemname`) and resource attributes (`k8s_deployment_name`, `k8s_pod_name`) as nested objects. Lucene field-name queries against these (e.g. `applicationName:foo` or `severity:ERROR`) fail with "text search not supported on objects". Use **full-text search only** — combine quoted phrases and `AND`/`OR` to narrow results.

```
# Narrow by key terms from the error message
"connection refused" AND "my-service"

# Combine error class and location
"NullPointerException" AND "auth"

# Pin to a specific file/function in the stack trace
"join.go:110" AND "context canceled"

# Combine multiple identifiers (correlation IDs appear verbatim in the body)
"abc-123" AND "context canceled"

# Broaden when narrow search returns nothing
"context canceled"
```

When the result file is too large for the tool to return inline, it is saved to disk. Use `grep` on that file to extract timestamps and assess frequency:

```bash
# Count errors per minute
grep "    timestamp:" /path/to/result.txt | cut -c15-29 | sort | uniq -c

# List unique pod names
grep "k8s_pod_name" /path/to/result.txt | sort -u
```

## Step 3: Gather Surrounding Context

After locating the error, expand the search:

1. **Same trace:** Search for any correlation IDs (trace ID, request ID) that appeared in Step 2 results — shows the full request lifecycle
2. **Same time window, same service:** Broaden to all logs from the same service keyword in the ±1 minute window
3. **Upstream/downstream services:** Search for related service names at the same timestamp
4. **7-day history:** Widen `startDate`/`endDate` to 7 days with the same text query, then grep the saved file by day:

```bash
grep "    timestamp:" /path/to/7day-result.txt | cut -c15-24 | sort | uniq -c
```

## Step 4: Noise vs. Real Problem

**Signals it's a real problem:**
- Sudden spike — error rate increased near a recent deploy or config change
- Correlated user impact — elevated 5xx responses, latency spikes, support tickets
- New error — no occurrences in the 7-day history before a recent event
- Clusters around specific inputs — particular endpoints, users, or data patterns
- Related failures in other services at the same time

**Signals it's noise:**
- Flat, constant low rate with no spikes
- Predates all recent changes (error has existed for weeks or months)
- Expected condition being logged at wrong severity (e.g., 404 for optional resource, auth failure from a bot/crawler)
- No correlation with business metrics (conversion, latency, error budget)

## Step 5: Output

Always open the summary with the originally supplied error, formatted as a JSON code block, so the report is self-contained:

````
## Investigation Summary

### Submitted Error
```json
{ ...original error pasted verbatim here... }
```
````

**Real problem:**
1. State the error pattern: frequency, affected service(s), time range
2. Identify the most likely root cause from log evidence
3. Quote the most relevant log lines as evidence
4. Suggest specific fixes or next investigation steps (check dependency health, review recent deploys, inspect specific config)

**Noise:**
1. State why it appears to be noise (flat rate, long history, no user impact)
2. Recommend a suppression strategy (see below)

**Include Coralogix view links in every section of the summary:**

- **From a Coralogix email report:** Extract the "View error" href links from the email and add them as `[View in Coralogix](url)` at the end of each error section. The email uses quoted-printable encoding — decode soft line breaks (trailing `=`) and replace `=3D` → `=` in the href attribute boundary to reconstruct the full URL.
- **From MCP queries:** If query results include a Coralogix UI URL or log permalink, include it. Otherwise add the DataPrime/Lucene query used so the user can reproduce the view: `[Reproduce in Coralogix](https://dashboard.coralogix.com/#/query-new/logs?query=...)`.

After delivering the summary, ask:

> "Would you like me to save this summary to a markdown file? Default location: `~/Documents/coralogix-error-summaries/`"

If yes, use a filename derived from the service name and timestamp (e.g. `teleport-auth-2026-06-02.md`). Do not write the file unless the user confirms.

**Do not offer to implement any recommended fix, suppression rule, or configuration change.** Present recommendations only. If the user wants something applied, they will ask.

### Batch report format (daily digest)

When triaging a daily email, the report covers the **full list**, then drills in only on the keepers:

1. **Disposition table** — one row per error in the email:

   | Error | Service | Env | Count | Disposition | Why |
   |-------|---------|-----|-------|-------------|-----|
   | ... | ... | prod | 1.2K | investigate | new — no history before today |
   | ... | ... | stage | 400K | noise | flat 7-day trend, non-prod |

   For any error promoted by the signal guard, cite the trend evidence ("new — first seen today", "spiking — 3× day-over-day") in the Why column.

2. **Investigation sections** — a full Step 5 summary for each `investigate` error only. Noise/dismissed errors stay in the table and are not expanded.

## Noise Suppression Options

Present these options ranked by impact; do not apply automatically — confirm with user first.

| Option | When to use | Tool |
|--------|-------------|------|
| **Parsing rule** — block at ingestion | Log is truly useless; reduces cost | `mcp__coralogix__create_simple_parsing_rule` |
| **Log level fix** — change severity in code | App logging expected condition as ERROR | Code change (no MCP tool) |
| **Alert threshold tuning** — raise alert floor | Log is fine to keep, just shouldn't page | `mcp__coralogix__list_alert_definitions` → suggest threshold change |
| **Sampling rule** — keep a percentage | Log has some value but fires too frequently | `mcp__coralogix__create_simple_parsing_rule` with sample action |

Before creating any rule, run `mcp__coralogix__list_rule_groups` to check for existing rules that may already apply.

## MCP Tool Quick Reference

| Task | Tool |
|------|------|
| Search logs by text/field | `mcp__coralogix__query_lucene` |
| Count, aggregate, trend | `mcp__coralogix__query_dataprime` |
| Query archived logs | `mcp__coralogix__query_archived_logs` |
| Long-running analysis | `mcp__coralogix__submit_background_query` → `get_background_query_status` → `get_background_query_data` |
| List existing parsing rules | `mcp__coralogix__list_rule_groups` |
| Create block/sample rule | `mcp__coralogix__create_simple_parsing_rule` |
| Find related alerts | `mcp__coralogix__list_alert_definitions` |
| Get alert event history | `mcp__coralogix__get_alert_events` |
| Validate a query before running | `mcp__coralogix__validate_query_syntax` |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `field:value` Lucene syntax | Labels and resource attributes are nested objects — field addressing fails. Use full-text search only. |
| Querying without a time window | Always scope to a time range; Coralogix has massive data volumes |
| Only searching the exact error message | Combine with service keywords, stack frame locations (`join.go:110`), or correlation IDs |
| Treating every error as critical | Check frequency history before recommending urgent fixes |
| Assuming high-volume errors are production | Always read `k8s_cluster_name` per error — occurrence count does not imply environment |
| Querying to prove a digest error is "new" | The "New Errors" report already guarantees novelty — spend the one query on "is it still happening now?" instead |
| Trying `list_alert_definitions`/`search_alerts` to find the digest's source | Those endpoints 404 in this region, and the digest is Error Tracking, not an alert — fetch and parse the email instead |
| Reading the 150K-char digest thread inline | `get_thread` saves it to disk — parse the saved file with the Step-2 parser |
| Creating suppression rules immediately | Confirm with user; understand impact before applying |
| Using Dataprime for point lookups | Use Lucene for finding specific log lines; Dataprime for aggregations |
| Trying to read oversized result files inline | Results saved to disk when too large — grep the file for `    timestamp:` or `k8s_pod_name` patterns instead |

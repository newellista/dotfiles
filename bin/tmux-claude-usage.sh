#!/usr/bin/env bash
# tmux status-right segment: Claude usage from openusage.
#
# Emits e.g.  #[fg=colour160]CLD 96% $481/$500#[default]
#
# status-interval is 1s, so the formatted string is cached locally to avoid
# exec'ing openusage + jq every second (openusage has its own 5min cache).
set -uo pipefail

CACHE="${TMPDIR:-/tmp}/tmux-claude-usage.cache"
TTL=60

OK_COLOR=colour64      # green
WARN_COLOR=colour136   # yellow
CRIT_COLOR=colour160   # red
WARN_AT=70
CRIT_AT=90

now=$(date +%s)

if [[ -f "$CACHE" ]]; then
  IFS=$'\t' read -r cached_at cached_text < "$CACHE"
  if [[ -n "${cached_at:-}" ]] && (( now - cached_at < TTL )); then
    printf '%s' "$cached_text"
    exit 0
  fi
fi

render() {
  printf '%s\t%s\n' "$now" "$1" > "$CACHE"
  printf '%s' "$1"
}

command -v openusage >/dev/null 2>&1 || { render "#[fg=$WARN_COLOR]CLD n/a#[default]"; exit 0; }
command -v jq >/dev/null 2>&1 || { render "#[fg=$WARN_COLOR]CLD n/a#[default]"; exit 0; }

json=$(openusage claude 2>/dev/null)
[[ -n "$json" ]] || { render "#[fg=$WARN_COLOR]CLD ?#[default]"; exit 0; }

# Prefer a percentage-style limit if the plan exposes one; otherwise fall back
# to the consumption pool (Enterprise only exposes extraUsage).
read -r pct used limit unit < <(
  jq -r '
    (.providers.claude.resources // {})
    | (.session? // .weekly? // .extraUsage? // .[]?)
    | select(. != null)
    | [ ((.utilization // 0) * 100 | round),
        (.used // 0 | round),
        (.limit // 0 | round),
        (.unit // "") ]
    | @tsv
  ' <<< "$json" | head -1 | tr '\t' ' '
)

[[ -n "${pct:-}" ]] || { render "#[fg=$WARN_COLOR]CLD ?#[default]"; exit 0; }

if   (( pct >= CRIT_AT )); then color=$CRIT_COLOR
elif (( pct >= WARN_AT )); then color=$WARN_COLOR
else color=$OK_COLOR
fi

if [[ "$unit" == "usd" ]]; then
  amount="\$${used}/\$${limit}"
else
  amount="${used}/${limit}"
fi

render "#[fg=$color]CLD ${pct}% ${amount}#[default]"

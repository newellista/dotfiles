#!/bin/bash
# md-to-rtf.sh — convert Markdown calibration/Workday docs to RTF (rich text) for pasting into Workday.
# No pandoc on this machine; uses a simple md->HTML pass + macOS `textutil` (HTML->RTF).
# Handles the subset these docs use: # / ## headers, - bullet lists, **bold**, *italic*, `code`, [text](url), --- rules, paragraphs.
# Usage:  md-to-rtf.sh <file1.md> [file2.md ...]        # RTF written next to each .md
#         md-to-rtf.sh <dir>                            # converts *-workday-review.md in dir
set -euo pipefail
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
PY="$TMP/md2html.py"
cat > "$PY" <<'PYEOF'
import sys, re, html
def inline(t):
    t = html.escape(t, quote=False)
    t = re.sub(r'`([^`]+)`', r'<code>\1</code>', t)
    t = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', t)
    t = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', t)
    t = re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)', r'<em>\1</em>', t)
    return t
def convert(md):
    out=[]; in_ul=False
    def close_ul():
        nonlocal in_ul
        if in_ul: out.append('</ul>'); in_ul=False
    for line in md.split('\n'):
        line=line.rstrip()
        if re.match(r'^\s*-\s+', line):
            if not in_ul: out.append('<ul>'); in_ul=True
            out.append('<li>'+inline(re.sub(r'^\s*-\s+','',line))+'</li>'); continue
        close_ul()
        if not line.strip(): continue
        m=re.match(r'^(#{1,6})\s+(.*)$', line)
        if m:
            l=len(m.group(1)); out.append(f'<h{l}>'+inline(m.group(2))+f'</h{l}>'); continue
        if re.match(r'^\s*---\s*$', line): out.append('<hr/>'); continue
        out.append('<p>'+inline(line)+'</p>')
    close_ul()
    return '<!DOCTYPE html><html><head><meta charset="utf-8"></head><body>'+'\n'.join(out)+'</body></html>'
with open(sys.argv[1],encoding='utf-8') as f: sys.stdout.write(convert(f.read()))
PYEOF
files=()
if [ "$#" -eq 1 ] && [ -d "$1" ]; then
  for f in "$1"/*-workday-review.md; do files+=("$f"); done
else
  files=("$@")
fi
for f in "${files[@]}"; do
  base="${f%.md}"; html="$TMP/$(basename "$base").html"
  python3 "$PY" "$f" > "$html"
  textutil -convert rtf -output "$base.rtf" "$html"
  echo "wrote $base.rtf"
done

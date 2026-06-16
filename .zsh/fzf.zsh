# Avoid alias collisions
for name in ff fg fcd gb gc gf; do
  unalias $name 2>/dev/null
done

# ─────────────────────────────────────────────────────────────
# fzf defaults (fast, ripgrep-powered)
# ─────────────────────────────────────────────────────────────

export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --inline-info
'

# Ctrl-T: file picker with preview
export FZF_CTRL_T_OPTS="
  --preview 'bat --style=numbers --color=always {}'
"

# Alt-C: directory picker
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="
  --preview 'tree -C {} | head -100'
"

# ─────────────────────────────────────────────────────────────
# Core fzf functions (muscle-memory friendly)
# ─────────────────────────────────────────────────────────────

# ff — find file (with preview)
ff() {
  fzf --ansi \
      --preview 'bat --style=numbers --color=always --pager=never {}' \
      --preview-window=right:60%:wrap \
      --bind "enter:execute-silent(sh -c 'tmux split-window -h -c \"#{pane_current_path}\" \"$EDITOR \"\"{1}\"\"\"')+abort"
}

# fg — ripgrep + fzf (global search)
# usage: fg <pattern>
fg() {
  local query="${1:-.}"

  rg --line-number --no-heading --color=always "$query" |
  fzf --ansi \
      --delimiter : \
      --preview '
        rg --color=always --context 5 "'"$query"'" {1} |
        bat --style=numbers --color=always
      ' \
      --preview-window=right:60%:wrap \
      --bind "enter:execute-silent(sh -c 'tmux split-window -h -c \"#{pane_current_path}\" \"$EDITOR +{2} \"\"{1}\"\"\"')+abort"
}

# fcd — jump to directory
fcd() {
  fd --type d --hidden --follow --exclude .git |
  fzf |
  xargs cd
}

# ─────────────────────────────────────────────────────────────
# Safety: only load if fzf exists
# ─────────────────────────────────────────────────────────────

command -v fzf >/dev/null || return

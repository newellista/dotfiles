#!/usr/bin/env zsh
# -------------------------------
# Git helper functions
# -------------------------------

# Example git functions
gb() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repo"; read -k "?Press any key to close"; return; }
  git branch --all --color=always | grep -v HEAD | sed 's/^..//' | fzf --ansi --preview 'git log --oneline --decorate --color=always {1}' | xargs -r git checkout
}

gc() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repo"; read -k "?Press any key to close"; return; }
  git log --oneline --decorate --color=always | fzf --ansi --preview 'git show --color=always {1}' --preview-window=down:60%:wrap
}

gf() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repo"; read -k "?Press any key to close"; return; }
  git ls-files | fzf --preview 'git diff --color=always -- {}' --preview-window=up:60%:wrap
}

gs() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repo"; read -k "?Press any key to close"; return; }
  git status --short --color=always | fzf --ansi --multi --preview 'git diff --color=always {1}' --preview-window=up:60%:wrap
}

unalias gg 2>/dev/null
gg() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repo"; read -k "?Press any key to close"; return; }
  git ls-files | xargs rg --line-number --color=always "${1:-.}" | fzf --ansi --delimiter : --preview 'bat --color=always {1} --highlight-line {2}'
}

# -------------------------------
# Mapping for gh dashboard
# -------------------------------
# Format: key|description|function_name
git_mappings=(
  "b|Display all git branches|gb"
  "c|Display git commits|gc"
  "f|Browse git files with diff preview|gf"
  "s|Browse git status interactively|gs"
  "g|Search git grep|gg"
)

ga() {
  # Ensure mappings are loaded
  [[ -z $git_mappings ]] && return

  # Build fzf input
  local fzf_input=""
  for entry in "${git_mappings[@]}"; do
    local key="${entry%%|*}"
    local desc="$(echo "$entry" | cut -d'|' -f2)"
    fzf_input+="$key → $desc"$'\n'
  done

  # Launch fzf with TUI options
  local fzf_output selected_key selected_line func
  fzf_output=$(echo "$fzf_input" | fzf \
    --ansi --no-sort --reverse --prompt="Git Dashboard> " --height=80% \
    --expect=enter,esc)

  [[ -z $fzf_output ]] && return
  selected_key=$(head -n1 <<< "$fzf_output")
  selected_line=$(tail -n1 <<< "$fzf_output")
  [[ "$selected_key" != "enter" ]] && return

  # Extract key and find function
  local key="${selected_line%% →*}"
  for entry in "${git_mappings[@]}"; do
    [[ $entry == "$key|"* ]] && func="${entry##*|}" && break
  done

  [[ -z $func ]] && { echo "Function not found"; return; }

  # Run the function directly in the popup
  "$func"
}

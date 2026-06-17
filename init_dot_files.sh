#!/usr/bin/env bash
# Bootstrap dotfiles on this machine: symlink configs, init plugin submodules,
# link shared agent skills, then report what still needs manual setup.
#
# Safe to re-run. A correct link is left alone; a wrong link is repointed; an
# existing real file is moved to <name>.bak before being replaced.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "  ok        ${dest/#$HOME/~}"
    return
  fi
  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    mv "$dest" "$dest.bak"
    echo "  backed up ${dest/#$HOME/~} -> $(basename "$dest").bak"
  fi
  ln -sfn "$src" "$dest"
  echo "  linked    ${dest/#$HOME/~}"
}

echo "Linking top-level dotfiles..."
for entry in "$DOTFILES"/.*; do
  [[ -d "$entry" ]] && continue
  name="$(basename "$entry")"
  case "$name" in
    .|..|.git|.gitmodules|.gitignore|.DS_Store) continue ;;
  esac
  link "$entry" "$HOME/$name"
done

echo "Linking config directories..."
link "$DOTFILES/vim"  "$HOME/.vim"
link "$DOTFILES/tmux" "$HOME/.tmux"
link "$DOTFILES/.zsh" "$HOME/.zsh"

echo "Linking shared agent skills..."
targets="$DOTFILES/skills/targets.conf"
if [[ -f "$targets" ]]; then
  while read -r skill tools; do
    [[ -z "$skill" || "$skill" == \#* ]] && continue
    src="$DOTFILES/skills/$skill"
    if [[ ! -d "$src" ]]; then
      echo "  WARN      skills/$skill is in targets.conf but missing"
      continue
    fi
    for tool in ${tools//,/ }; do
      case "$tool" in
        claude) dest="$HOME/.claude/skills/$skill" ;;
        cursor) dest="$HOME/.cursor/skills/$skill" ;;
        *) echo "  WARN      unknown tool '$tool' for skill $skill"; continue ;;
      esac
      mkdir -p "$(dirname "$dest")"
      link "$src" "$dest"
    done
  done < "$targets"
else
  echo "  (no skills/targets.conf — skipping)"
fi

echo "Updating git submodules (vim/tmux plugins)..."
git -C "$DOTFILES" submodule update --init --recursive

echo "Checking for expected tools..."
missing=0
check() {
  if eval "$2" >/dev/null 2>&1; then
    echo "  ✓ $1"
  else
    echo "  ✗ $1 — $3"
    missing=$((missing + 1))
  fi
}
check "oh-my-zsh" "[ -d \"$HOME/.oh-my-zsh\" ]" 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
check "starship"  "command -v starship" "brew install starship"
check "fzf"       "command -v fzf"      "brew install fzf"
check "ripgrep"   "command -v rg"       "brew install ripgrep"
check "tmux"      "command -v tmux"     "brew install tmux"
check "asdf"      "command -v asdf"     "brew install asdf"

echo
echo "Manual steps this script does NOT do:"
echo "  - Create ~/.global.env with your secrets (gitignored; see README)."
echo "  - On a work machine, create ~/.work.zsh for corporate config (see README)."
echo "  - Re-auth tooling: gh auth login, and MCP servers via /mcp in Claude Code."
echo "  - Vim helptags: open vim and run :helptags ALL"
echo "  - In tmux, press prefix + I to install plugins via tpm."
[[ $missing -gt 0 ]] && echo "  - Install the $missing tool(s) marked ✗ above."
echo "Done."

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
  
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  history
  common-aliases
  tmux
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ ! -f ~/.myaliases ]] || source ~/.myaliases

export EDITOR=vi
set -o vi

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

export CPPFLAGS='-I/opt/homebrew/opt/libpq/include -I/opt/homebrew/opt/mysql@5.7/include'
export GOBIN=/Users/steve.newell/.asdf/installs/golang/1.24.1/bin
export GOPATH=/Users/steve.newell/.asdf/installs/golang/1.24.1/packages
export GOROOT=/Users/steve.newell/.asdf/installs/golang/1.24.1/go
export LDFLAGS='-L/opt/homebrew/opt/libpq/lib -L/opt/homebrew/opt/mysql@5.7/lib'
export VAULT_ADDR=https://vault.lvt-platform-ops.aws.lvt.cloud/

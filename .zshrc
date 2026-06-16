export ZSH="$HOME/.oh-my-zsh"
export XDG_CONFIG_HOME="/Users/steve.newell/dotfiles"

plugins=(
  git
  history
  common-aliases
  tmux
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

[[ ! -f ~/.myaliases ]] || source ~/.myaliases

export EDITOR=vim
set -o vi

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

export CPPFLAGS='-I/opt/homebrew/opt/libpq/include -I/opt/homebrew/opt/mysql@5.7/include'
# export GOBIN=/Users/steve.newell/.asdf/installs/golang/1.24.1/bin
# export GOPATH=/Users/steve.newell/.asdf/installs/golang/1.24.1/packages
# export GOROOT=/Users/steve.newell/.asdf/installs/golang/1.24.1/go
export LDFLAGS='-L/opt/homebrew/opt/libpq/lib -L/opt/homebrew/opt/mysql@5.7/lib'
export VAULT_ADDR=https://vault.lvt-platform-ops.aws.lvt.cloud/

# asdf support
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
# Add support for Android Studio
export ANDROID_HOME=~/Library/Android/sdk

export PATH=/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin:$PATH
export PATH=/opt/homebrew/share/android-commandlinetools/emulator:$PATH
export PATH=/opt/homebrew/share/android-commandlinetools/platform-tools:$PATH

# Don't include API keys or secrets in .zshrc, as we don't want them stored in GitHub.
# Instead, add them to .global.env, which will be included here, but not checked into 
# GitHub

[[ ! -f ~/.global.env ]] || source ~/.global.env
export REQUESTS_CA_BUNDLE="/Users/steve.newell/.netskope/nscacert_combined.pem"
export NODE_EXTRA_CA_CERTS="/Users/steve.newell/.netskope/nscacert_combined.pem"
export CURL_CA_BUNDLE="/Users/steve.newell/.netskope/nscacert_combined.pem"
export SSL_CERT_FILE="/Users/steve.newell/.netskope/nscacert_combined.pem"
export GIT_SSL_CAINFO="/Users/steve.newell/.netskope/nscacert_combined.pem"
export AWS_CA_BUNDLE="/Users/steve.newell/.netskope/nscacert_combined.pem"

export STARSHIP_CONFIG="$HOME/dotfiles/starship.toml"
eval "$(starship init zsh)"

[[ ! -f ~/.zsh/fzf.zsh ]] || source ~/.zsh/fzf.zsh
# [[ ! -f ~/.zsh/gitfunctions.zsh ]] || source ~/.zsh/gitfunctions.zsh
export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/steve.newell/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "/Users/steve.newell/.bun/_bun" ] && source "/Users/steve.newell/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

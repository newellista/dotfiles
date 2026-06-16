
ff() {
  fzf --preview 'bat --style=numbers --color=always {}'
}


fg() {
  rg --line-number --no-heading --color=always "${1:-.}" |
  fzf --ansi \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}'
}

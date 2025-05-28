#!/bin/sh

homedir=~
dotfiles_dir=$homedir/dotfiles
config_directories=("vim" "tmux" "iterm2")

for dir in ${config_directories[@]}; do
  destination=$homedir/.$dir

  if [[ ! -d "$destination" ]]; then
    echo "Creating symlink from $dir to $destination"
    ln -s $dotfiles_dir/$dir $destination
  fi
done

for entry in "$dotfiles_dir"/.*
do
  filename="$(basename -- $entry)"

  if [[ ! -f "$homedir/$filename" ]] && 
     [[ ! -d "$entry" ]] && 
     [[ $filename != ".gitmodules"  ]] && 
     [[ $filename != ".git" ]]  ; then
    echo "Creating symlink from $filename to $homedir/$filename"
    ln -s $entry $homedir/$filename
  fi
done

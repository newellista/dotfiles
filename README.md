# dotfiles
### Replicating the repository on a machine
- Clone the repository (_recursively_ to clone plugins as well):

    ```
    git clone --recursive https://github.com/newellista/dotfiles.git
    ```
    
- Symlink `.vim` and `.vimrc`:

    ```
    ln -sf dotfiles ~/.vim
    ln -sf dotfiles/.vimrc ~/.vimrc
    ```
    
- Generate helptags for plugins:
    ```
    vim
    :helptags ALL
    ```
    
### Installing plugins
To install plugins (say always-loaded `foo` and optionally-loaded `bar`, located at `https://github.com/manasthakur/foo` and `https://github.com/manasthakur/bar`, respectively) using Vim 8's package feature:
```
git submodule add https://github.com/manasthakur/foo.git vim/pack/plugins/start/foo
git submodule add https://github.com/manasthakur/bar.git vim/pack/plugins/opt/bar
git commit -m "Added submodules."
```

### Updating plugins
To update `foo`:
```
cd ~/.vim/pack/plugins/start/foo
git pull origin master
```
It is recommended to first `git fetch origin master` a plugin, review changes, and then `git merge`.

To update all the plugins:
```
cd ~/dotfiles
git submodule foreach git pull origin master
```

Note that new commits to plugins create uncommitted changes in the main repository.
Thus, after any updates in the submodules, you need to commit the main repository as well:
```
cd ~/dotfiles
git commit -am "Updated plugins."
```

Source [gist](https://gist.github.com/manasthakur/d4dc9a610884c60d944a4dd97f0b3560)

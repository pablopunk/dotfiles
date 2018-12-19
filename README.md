# dotfiles

I usually keep the repo in `~/.dotfiles`:

```shell
git clone https://github.com/pablopunk/dotfiles ~/.dotfiles
```

You can install all dotfiles at once:

```shell
$ bash install.sh
'~/.bash_profile'         -> '~/.dotfiles/bash/bash_profile'
'~/.bashrc'               -> '~/.dotfiles/bash/bashrc'
'~/.inputrc'              -> '~/.dotfiles/bash/inputrc'
'~/.editorconfig'         -> '~/.dotfiles/editorconfig/editorconfig'
'~/.hyper.js'             -> '~/.dotfiles/hyper/hyper.js'
'~/.config/nvim/init.vim' -> '~/.dotfiles/nvim/config/nvim/init.vim'
'~/.tern-project'         -> '~/.dotfiles/tern/tern-project'
'~/.tmux.conf'            -> '~/.dotfiles/tmux/tmux.conf'
'~/.vimrc'                -> '~/.dotfiles/vim/vimrc'
```

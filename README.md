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

# Contents

- bash
  - aliases
  - `.inputrc` to complete bash history with arrow keys
  - [bashy prompt](https://github.com/pablopunk/bashy)
- editorconfig
  - basic editorconfig global settings
- hyper
  - really basic config
- nvim
  - delegates all configs to `~/.vimrc`
- tmux
  - controls to navigate between tmux panes and vim panes
- vim
  - more plugins than I need
  - a lot of things I don't wanna talk about

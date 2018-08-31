# dotfiles

I usually keep the repo in `~/.dotfiles`:

```shell
git clone https://github.com/pablopunk/dotfiles ~/.dotfiles
```

You can install all dotfiles at once:

```shell
$ bash install.sh
'~/.bashrc'               -> '~/.dotfiles/bash/bashrc'
'~/.inputrc'              -> '~/.dotfiles/bash/inputrc'
'~/.editorconfig'         -> '~/.dotfiles/editorconfig/editorconfig'
'~/.hyper.js'             -> '~/.dotfiles/hyper/hyper.js'
'~/.config/nvim/init.vim' -> '~/.dotfiles/nvim/config/nvim/init.vim'
'~/.tmux.conf'            -> '~/.dotfiles/tmux/tmux.conf'
'~/.vimrc'                -> '~/.dotfiles/vim/vimrc'
```

Or just the one you want:

```shell
$ bash vim/install.sh
~/.vimrc -> ~/.dotfiles/vim/vimrc
```

# Contents

- bash
  - aliases
  - `.inputrc` to complete bash history with arrow keys
  - [bashy prompt](https://github.com/pablopunk/bashy)
- editorconfig
  - basic editorconfig global settings
- hyper
  - really basic config (just one plugin I think)
- nvim
  - delegates all configs to `~/.vimrc`
- tmux
  - controls to navigate between tmux panes and vim panes
  - plugin manager
- vim
  - more plugins than I need
  - a lot of things I don't wanna talk about

# dotfiles

I usually keep the repo in `~/.dotfiles`:

```shell
git clone https://github.com/pablopunk/dotfiles ~/.dotfiles
```

You can install all dotfiles at once:

```shell
$ bash install.sh
~/.bash_profile -> ~/.dotfiles/bash/bashrc
~/.inputrc -> ~/.dotfiles/bash/inputrc
~/.hyper.js -> ~/.dotfiles/hyper/hyper.js
~/.tmux.conf -> ~/.dotfiles/tmux/tmux.conf
~/.vimrc -> ~/.dotfiles/vim/vimrc
~/.zshrc -> ~/.dotfiles/zsh/zshrc
```

Or just the one you want:

```shell
$ bash vim/install.sh # install just vimrc
~/.vimrc -> ~/.dotfiles/vim/vimrc
```

# Contents

- bash
  - aliases
  - [bashy prompt](https://github.com/pablopunk/bashy)
- hyper
  - really basic config (just one plugin I think)
- tmux
  - controls to navigate between tmux panes and vim panes
  - plugin manager
- vim
  - more plugins than I need
  - a lot of things I don't wanna talk about
- zsh
  - pure prompt

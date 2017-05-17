# dotfiles

You can install all dotfiles at once:

```shell
$ bash install.sh 
~/.bash_profile -> ~/.dotfiles/bash/bashrc
~/.inputrc -> ~/.dotfiles/bash/inputrc
~/.hyper.js -> ~/.dotfiles/hyper/hyper.js
~/.vimrc -> ~/.dotfiles/vim/vimrc
~/.zshrc -> ~/.dotfiles/zsh/zshrc
~/.dotfiles -> ~/.dotfiles
```

Or just the one you want:

```shell
$ bash vim/install.sh # install just vimrc
~/.vimrc -> ~/.dotfiles/vim/vimrc
```


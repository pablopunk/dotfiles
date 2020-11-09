#!/bin/bash

function preinstall {
  rm -rf .vim
  mkdir -p .vim
  curl -sfLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    > /dev/null
}

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# link config file
preinstall && \
  ln -svf $dir/vimrc ~/.vimrc && \
  ln -svf $dir/vimrc.min ~/.vimrc.min
  ln -svf $dir/../nvim/coc-settings.json ~/.vim/coc-settings.json

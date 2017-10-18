#!/bin/bash

file_name='vimrc'

function preinstall {
  curl -sfLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    > /dev/null
}

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# link config file
preinstall && ln -svf $dir/$file_name ~/.$file_name

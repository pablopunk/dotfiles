#!/bin/bash

file_name='vimrc'

function preinstall {
  curl -sfLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    > /dev/null
}

# get script directory
pushd `dirname $0` > /dev/null
dir=`pwd -P`
popd > /dev/null

# link config file
preinstall && ln -svf $dir/$file_name ~/.$file_name

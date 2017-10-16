#!/bin/bash

file_name='config/nvim/init.vim'

function preinstall {
  mkdir -p ~/.config/nvim
}

# get script directory
pushd `dirname $0` > /dev/null
dir=`pwd -P`
popd > /dev/null

# link config file
preinstall && ln -svf $dir/$file_name ~/.$file_name

#!/bin/bash

file_name='config/nvim/init.vim'

function preinstall {
  mkdir -p ~/.config/nvim
}

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# link config file
preinstall && ln -svf $dir/$file_name ~/.$file_name

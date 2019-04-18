#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p ~/.config/nvim
file_name='config/nvim/init.vim'
ln -svf $dir/$file_name ~/.$file_name
file_name='config/nvim/coc-settings.json'
ln -svf $dir/$file_name ~/.$file_name

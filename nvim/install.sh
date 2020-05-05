#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p ~/.config/nvim

files=( "init.vim" "coc-settings.json" "templates" )

for file_name in "${files[@]}"
do
  rm ~/.config/nvim/$file_name
  ln -svf $dir/$file_name ~/.config/nvim/$file_name
done

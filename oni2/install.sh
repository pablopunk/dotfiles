#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p ~/.config/oni2

files=( "keybindings.json", "configuration.json" )

for file_name in "${files[@]}"
do
  rm ~/.config/oni2/$file_name
  ln -svf $dir/$file_name ~/.config/oni2/$file_name
done





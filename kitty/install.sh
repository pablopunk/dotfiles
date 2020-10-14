#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p ~/.config/kitty

files=( "kitty.conf" )

for file_name in "${files[@]}"
do
  rm ~/.config/kitty/$file_name
  ln -svf $dir/$file_name ~/.config/kitty/$file_name
done





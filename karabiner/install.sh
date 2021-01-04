#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p ~/.config/karabiner

files=( "karabiner.json" )

for file_name in "${files[@]}"
do
  rm ~/.config/karabiner/$file_name
  ln -svf $dir/$file_name ~/.config/karabiner/$file_name
done


#!/bin/bash

mkdir -p ~/.config/zellij
dir="$(dirname $(realpath $0))"

# find all file names under ./zellij/*kdl
for file in $(ls -1 "$dir"/*kdl ); do
  file_name=$(basename "$file")
  ln -svf "$file" "$HOME/.config/zellij/$file_name"
done


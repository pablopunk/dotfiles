#!/bin/bash

dir="$(dirname $(realpath $0))"

mkdir -p ~/.config/

rm -rf ~/.config/karabiner
ln -sf $dir ~/.config/karabiner


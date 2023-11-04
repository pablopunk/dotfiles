#!/bin/bash

dir="$(dirname $(realpath $0))"

mkdir -p ~/.config/

rm -rf ~/.config/karabiner
ln -svf $dir ~/.config/karabiner


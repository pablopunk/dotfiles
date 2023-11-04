#!/bin/bash

dir="$(dirname $(realpath $0))"

rm -rf ~/.config/nvim
ln -svf $dir ~/.config/nvim

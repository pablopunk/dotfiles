#!/bin/bash

dir="$(dirname $(realpath $0))"

rm -rf ~/.config/nvim
ln -svf $dir ~/.config/nvim

echo "Installing neovim plugins..."
nvim --headless "+Lazy! install" "+Lazy! update" +qa > /dev/null

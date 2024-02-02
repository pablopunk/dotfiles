#!/bin/bash

dir="$(dirname $(realpath $0))"

rm -rf ~/.config/nvim
ln -sf $dir ~/.config/nvim

echo "Installing neovim plugins..."
nvim --headless "+Lazy! install" "+Lazy! update" +qa > /dev/null

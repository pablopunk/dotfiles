#!/bin/bash

ln -sf $(dirname $(realpath $0))/tmux.conf ~/.tmux.conf

plugins_dir=~/.tmux/plugins
[ -d $plugins_dir/tpm ] && exit

mkdir -p $plugins_dir
git clone https://github.com/tmux-plugins/tpm $plugins_dir/tpm

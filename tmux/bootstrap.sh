#!/bin/bash

if ! hash tmux 2>/dev/null; then
  brew install tmux
fi

plugins_dir=~/.tmux/plugins
if [[ ! -d $plugins_dir/tpm ]]; then
  mkdir -p $plugins_dir
  git clone https://github.com/tmux-plugins/tpm $plugins_dir/tpm
fi

#!/bin/bash

function preinstall {
  rm -rf ~/.tmux
  mkdir -p ~/.tmux/plugins
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# link config file
preinstall && \
  ln -svf $dir/tmux.conf ~/.tmux.conf

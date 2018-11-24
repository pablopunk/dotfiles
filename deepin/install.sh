#!/bin/bash

file_name='config/deepin/deepin-terminal/config.conf'

function preinstall {
  mkdir -p ~/.config/deepin/deepin-terminal
}

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# link config file
preinstall && ln -svf $dir/$file_name ~/.$file_name

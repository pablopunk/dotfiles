#!/bin/bash

file_name='tmux.conf'

function preinstall {
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

# get script directory
pushd `dirname $0` > /dev/null
dir=`pwd -P`
popd > /dev/null

# link config file
preinstall && ln -svf $dir/$file_name ~/.$file_name

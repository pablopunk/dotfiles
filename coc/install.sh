#!/bin/bash

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# link config files
ln -svf $dir/config/coc ~/.config/coc

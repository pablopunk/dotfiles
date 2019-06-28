#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

rm -rf ~/.config/karabiner
ln -svf $dir/config/karabiner ~/.config/karabiner

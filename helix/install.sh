#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p ~/.config
rm -rf ~/.config/helix
ln -svf $dir ~/.config/helix

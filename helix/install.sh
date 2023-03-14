#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

rm -rf ~/.config/helix
ln -svf $dir ~/.config/helix

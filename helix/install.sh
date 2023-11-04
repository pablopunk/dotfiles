#!/bin/bash

dir="$(dirname $(realpath $0))"

mkdir -p ~/.config
rm -rf ~/.config/helix
ln -svf $dir ~/.config/helix

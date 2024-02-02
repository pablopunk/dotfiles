#!/bin/bash

dir="$(dirname $(realpath $0))"

mkdir -p ~/.config
rm -rf ~/.config/helix
ln -sf $dir ~/.config/helix

#!/bin/bash

dir="$(dirname $(realpath $0))"

rm -rf ~/.config/sketchybar
ln -sf $dir ~/.config/sketchybar

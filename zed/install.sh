#!/bin/bash

dir="$(dirname $(realpath $0))"

rm -rf ~/.config/zed
ln -svf $dir ~/.config/zed

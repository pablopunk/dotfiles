#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

rm -rf ~/.config/zed
ln -svf $dir ~/.config/zed

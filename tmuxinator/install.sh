#!/bin/bash

dir=$(dirname $(realpath $0))
rm -rf ~/.tmuxinator
ln -sf $dir ~/.tmuxinator

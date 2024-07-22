#!/bin/bash

nvim --headless +qa > /dev/null 2>&1 # install plugins
mkdir -p $HOME/.cache/nvim

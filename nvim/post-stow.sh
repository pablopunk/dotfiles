#!/bin/bash

nvim --headless "+Lazy! install" "+Lazy! clean" +qa > /dev/null 2>&1 # install neovim plugins
NVIM_APPNAME=nvim nvim --headless +qa > /dev/null 2>&1 # install mvim plugins

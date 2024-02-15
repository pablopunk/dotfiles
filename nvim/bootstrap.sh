#!/bin/bash

if ! hash nvim 2>/dev/null; then
  brew install neovim --HEAD
fi


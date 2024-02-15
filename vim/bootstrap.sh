#!/bin/bash

if ! hash rg 2>/dev/null; then
  brew install ripgrep
fi

if ! hash vim 2>/dev/null; then
  brew install vim
fi

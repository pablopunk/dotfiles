#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  brew_install kitty
  brew_install homebrew/cask-fonts/font-sf-mono-for-powerline
fi


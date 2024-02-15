#!/bin/bash

if [[ -z $(brew list | grep kitty) ]]; then
  brew install kitty
  kitty +kitten themes --reload-in=all "Catppuccin-Mocha"
fi

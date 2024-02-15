#!/bin/bash

if [[ -z $(brew list | grep zsh-autosuggestions) ]]; then
  brew install zsh-autosuggestions zsh-syntax-highlighting
fi


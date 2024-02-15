#!/bin/bash

if ! hash zsh 2>/dev/null; then
  brew install zsh
fi

if [[ -z $(brew list | grep zsh-autosuggestions) ]]; then
  brew install zsh-autosuggestions zsh-syntax-highlighting
fi


#!/bin/bash

if ! hash zsh 2>/dev/null; then # might be installed outside of brew
  brew_install zsh
fi

brew_install zsh-autosuggestions
brew_install zsh-syntax-highlighting
brew_install zoxide
brew_install eza

#!/bin/bash

if ! hash zsh 2>/dev/null; then
  brew install zsh
fi

brew_list="$(cat /tmp/brew_list.txt)" # cached list
[[ -z $brew_list ]] && brew_list="$(brew list)"

if [[ -z "$(echo $brew_list | grep -w zsh-autosuggestions)" ]]; then
  brew install zsh-autosuggestions
fi

if [[ -z "$(echo $brew_list | grep -w zsh-syntax-highlighting)" ]]; then
  brew install zsh-syntax-highlighting
fi


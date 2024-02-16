#!/bin/bash

brew_list="$(cat /tmp/brew_list.txt)" # cached list
[[ -z $brew_list ]] && brew_list="$(brew list)"

if [[ -z "$(echo $brew_list | grep -w bash-completion)" ]]; then
  brew install bash-completion
fi

if [[ -z "$(echo $brew_list | grep -w zoxide)" ]]; then
  brew install zoxide
fi

#!/bin/bash

brew_list="$(cat /tmp/brew_list.txt)" # cached list
[[ -z $brew_list ]] && brew_list="$(brew list)"

if [[ -z "$(echo $brew_list | grep -w zellij)" ]]; then
  brew install zellij
fi




#!/bin/bash

if [[ -z $(brew list | grep alacritty) ]]; then
  brew install alacritty
fi


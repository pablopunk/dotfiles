#!/bin/bash

if [[ -z $(brew list | grep starship) ]]; then
  brew install starship
fi


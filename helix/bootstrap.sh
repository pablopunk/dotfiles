#!/bin/bash

if [[ -z $(brew list | grep helix) ]]; then
  brew install helix
fi


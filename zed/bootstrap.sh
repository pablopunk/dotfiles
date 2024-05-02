#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  if [[ ! -d "/Applications/Zed.app" ]] && [[ ! -d "/Applications/Zed Preview.app" ]]; then
    brew_install zed
  fi
fi


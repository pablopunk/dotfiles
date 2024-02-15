#!/bin/bash

if [[ -z $(brew list | grep zellij) ]]; then
  brew install zellij
fi


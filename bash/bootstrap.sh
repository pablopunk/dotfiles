#!/bin/bash

if [[ -z $(brew list | grep bash-completion) ]]; then
  brew install bash-completion
fi

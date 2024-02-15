#!/bin/bash

if [[ -z $(brew list | grep karabiner-elements) ]]; then
  brew install karabiner-elements
fi



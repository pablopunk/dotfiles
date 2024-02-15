#!/bin/bash

if ! hash mise 2>/dev/null;
then
  brew install mise
  eval "$(mise activate $(basename $SHELL))"
fi


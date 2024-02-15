#!/bin/bash

if [[ -z $(brew list | grep git-delta) ]]; then
  brew install git-delta
fi

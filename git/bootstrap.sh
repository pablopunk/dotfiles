#!/bin/bash

if ! hash git 2>/dev/null; then
  brew install git
fi

if ! hash delta 2>/dev/null; then
  brew install git-delta
fi

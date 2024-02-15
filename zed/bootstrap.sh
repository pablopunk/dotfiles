#!/bin/bash

if [[ -z $(brew list | grep zed) ]]; then
  brew install zed
fi


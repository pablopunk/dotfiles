#!/bin/bash

if ! hash git 2>/dev/null; then # might be installed outside of brew
  brew_install git
fi

brew_install git-delta

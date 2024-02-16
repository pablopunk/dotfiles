#!/bin/bash

if [[ -z "$(echo $brew_list | grep -w starship)" ]]; then
  brew_install starship
fi


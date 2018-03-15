#!/bin/bash

file_name='wakatime/bash-wakatime.sh'

function preinstall {
  # create wakatime folder if it doesn't exist
  mkdir -p $HOME/.wakatime
}

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# link config file
preinstall && ln -svf $dir/$file_name ~/.$file_name

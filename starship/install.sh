#!/bin/bash

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# link config file
mkdir -p ~/.config && ln -svf $dir/starship.toml ~/.config/starship.toml

#!/bin/bash

mkdir -p ~/.config
ln -sf "$(dirname $(realpath $0))/starship.toml" "$HOME/.config/starship.toml"

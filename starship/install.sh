#!/bin/bash

mkdir -p ~/.config
ln -svf "$(dirname $(realpath $0))/starship.toml" "$HOME/.config/starship.toml"

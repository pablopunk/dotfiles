#!/bin/bash

brew_install mise

# if node is a command already, exit
if ! hash node 2>/dev/null; then
  node_version=$(grep "node" ./mise/.config/mise/config.toml | cut -d '"' -f2)

  if [[ -z $node_version ]]; then
    echo "Error: node version not found in ./.config/mise/config.toml"
    exit 1
  fi

  mise use node@$node_version >/dev/null

  npm_bin="$HOME/.local/share/mise/installs/node/$node_version/bin/npm"
  npm_list=""
  function npm_install {
    [[ -z $npm_list ]] && npm_list="$($npm_bin list -g --depth=0)" # cache installed npm packages
    [[ -z "$(echo $npm_list | grep -w $1)" ]] && $npm_bin install -g $1 > /dev/null # install only if it's not installed
    echo -e "\033[32m✔︎\033[0m $1"
  }

  npm_install neovim
  npm_install odf
  npm_install pino-pretty
fi

#!/bin/bash

if ! hash stow 2>/dev/null; then
  brew install stow
fi

# get the directory of this script
dir="$(dirname $(realpath $0))"
pushd $dir > /dev/null

# loop in subdirectories
for script in `ls -1 */bootstrap.sh`
do
  bash $script
  echo -e "\033[32m✔︎\033[0m $(dirname "$script")"
done

popd > /dev/null

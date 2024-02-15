#!/bin/bash

# get script directory, cd into it
dir="$(dirname $(realpath $0))"
pushd $dir > /dev/null

for app in `ls -d1 */`
do
  stow "$app" --adopt --restow --ignore=bootstrap.sh --ignore=post-stow.sh
  [[ -f "$app/post-stow.sh" ]] && bash "$app/post-stow.sh"
  echo -e "\033[32m✔︎\033[0m $(basename "$app")"
done

popd > /dev/null

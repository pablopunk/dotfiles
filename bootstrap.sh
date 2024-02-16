#!/bin/bash

if [[ ! -f /opt/homebrew/bin/brew ]]; then
  hash brew 2>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

if ! hash stow 2>/dev/null; then
  brew install stow
fi

# get the directory of this script
dir="$(dirname $(realpath $0))"
pushd "$dir" > /dev/null


# Cache brew list
brew list > /tmp/brew-list.txt

# loop in subdirectories
for script in `ls -1 */bootstrap.sh`
do
  bash $script
  echo -e "\033[32m✔︎\033[0m $(dirname "$script")"
done

rm /tmp/brew-list.txt

popd > /dev/null

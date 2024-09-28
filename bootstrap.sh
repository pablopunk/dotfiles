#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  HOMEBREW_PREFIX="/opt/homebrew"
else
  HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi
if [[ ! -f "$HOMEBREW_PREFIX"/bin/brew ]]; then
  hash brew 2>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
eval "$(brew shellenv)"

# get the directory of this script
dir="$(dirname $(realpath $0))"
pushd "$dir" > /dev/null

function brew_install {
  package=$1
  package=$(echo $package | awk -F/ '{print $NF}') # split / and get last
  brew_list=$(cat /tmp/brew_list 2>/dev/null)
  [[ -z $brew_list ]] && brew_list="$(brew list)"
  echo $brew_list > /tmp/brew_list # cache brew list
  if [[ -z "$(echo $brew_list | grep -w $package)" ]]; then
    brew install $@ > /dev/null # install only if it's not installed
    echo -e "\033[94m✓\033[0m installed $1 (brew)"
  fi
}

echo
echo -e "\033[94mRunning bootstrap\033[0m"

brew_install stow

# export the function so it can be used in subscripts
export -f brew_install

# loop in subdirectories
for script in `ls -1 */bootstrap.sh`
do
  bash $script
  echo -e "\033[32m✓\033[0m $(dirname "$script")"
done

rm /tmp/brew_list

popd > /dev/null

#!/bin/bash

# get script directory, cd into it
dir="$(dirname $(realpath $0))"
pushd "$dir" > /dev/null

single_app=$1

# Function to safely remove symlink if it exists
remove_symlink_if_exists() {
  local symlink_path="$1"
  if [ -L "$symlink_path" ]; then # Check if it's a symlink
    echo "Removing existing symlink: $symlink_path"
    mv "$symlink_path" "$symlink_path.backup"
  fi
}

safely_stow() {
  app=$1
  # Before stowing, check and remove any existing symlinks that would cause conflicts
  while read -r line; do
    if [[ "$line" == *"existing target is not owned by stow:"* ]]; then
      # Extract the path of the conflicting file
      conflict_file="${line#*: }"
      # Check if this path is relative to the home directory
      if [[ "$conflict_file" == .* ]]; then
        conflict_file="$HOME/$conflict_file"
      fi
      remove_symlink_if_exists "$conflict_file"
    fi
  done < <(stow "$app" --adopt --no --ignore=bootstrap.sh --ignore=post-stow.sh 2>&1)

  # Now attempt to stow again after removing any problematic symlinks
  stow "$app" --adopt --ignore=bootstrap.sh --ignore=post-stow.sh
  if [[ -f "$app/post-stow.sh" ]]; then
    bash "$app/post-stow.sh"
  fi
  echo -e "\033[32m✔︎\033[0m $(basename "$app")"
}

if [ -n "$single_app" ]; then
  safely_stow "$single_app"
else
  for app in `ls -d1 */`
  do
    safely_stow "$app"
  done
fi

echo "bash link.sh" > .git/hooks/post-merge

popd > /dev/null


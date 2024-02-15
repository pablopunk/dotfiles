#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
pushd "$dir" > /dev/null

SUBDIR_NAME="$1"
TARGET_CONFIG="$2"

if [ -z "$SUBDIR_NAME" ] || [ -z "$TARGET_CONFIG" ]; then
  echo "Usage: $0 <subdir_name> <target_config>"
  exit 1
fi

# Ensure TARGET_CONFIG is an absolute path
if [[ "$TARGET_CONFIG" != /* ]]; then
  TARGET_CONFIG="$HOME/$TARGET_CONFIG"
fi

# Construct the source path from where to move the files/directories back to their original location
SOURCE_PATH="$dir/$SUBDIR_NAME/${TARGET_CONFIG#$HOME/}"

# Check if the source path exists
if [ ! -d "$SOURCE_PATH" ] && [ ! -f "$SOURCE_PATH" ]; then
  echo "Source path '$SOURCE_PATH' does not exist."
  exit 1
fi

# Make sure the target directory exists, backup if it does
TARGET_DIR=$(dirname "$TARGET_CONFIG")
if [ -d "$TARGET_CONFIG" ] || [ -f "$TARGET_CONFIG" ]; then
  mv "$TARGET_CONFIG" "$TARGET_CONFIG.backup"
fi

# If SOURCE_PATH is a directory, move its contents. If it's a file, just move it.
if [ -d "$SOURCE_PATH" ]; then
  # Create the target directory if not exists, as it's expected for directories
  mkdir -p "$TARGET_CONFIG"
  mv "$SOURCE_PATH"/* "$TARGET_CONFIG"/
  # Remove the source directory if it's empty
  rmdir "$SOURCE_PATH"
elif [ -f "$SOURCE_PATH" ]; then
  # If the target is a file, ensure its directory exists
  mkdir -p "$TARGET_DIR"
  mv "$SOURCE_PATH" "$TARGET_CONFIG"
fi

# Remove the now-empty subdirectory from .dotfiles, if empty
rm -rf "$dir/$SUBDIR_NAME"

echo "✔︎ Moved content from '$SUBDIR_NAME' back to '$TARGET_CONFIG' and backed up existing configuration."

popd > /dev/null


#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
pushd "$dir" > /dev/null

SUBDIR_NAME="$1"
SOURCE_CONFIG="$2"

if [ -z "$SUBDIR_NAME" ] || [ -z "$SOURCE_CONFIG" ]; then
  echo "Usage: $0 <name> <source_config>"
  exit 1
fi

SOURCE_CONFIG_ABSOLUTE=$(realpath "$SOURCE_CONFIG")
SOURCE_CONFIG_FROM_HOME="${SOURCE_CONFIG#$HOME/}"

# Determine if the source is a file or directory
if [ -d "$SOURCE_CONFIG_ABSOLUTE" ]; then
    mkdir -p "$SUBDIR_NAME/$SOURCE_CONFIG_FROM_HOME"
    mv "$SOURCE_CONFIG_ABSOLUTE"/* "$SUBDIR_NAME/$SOURCE_CONFIG_FROM_HOME"
elif [ -f "$SOURCE_CONFIG_ABSOLUTE" ]; then
    # Ensure the directory for the file exists
    mkdir -p "$SUBDIR_NAME/$(dirname "$SOURCE_CONFIG_FROM_HOME")"
    mv "$SOURCE_CONFIG_ABSOLUTE" "$SUBDIR_NAME/$SOURCE_CONFIG_FROM_HOME"
else
    echo "$SOURCE_CONFIG_ABSOLUTE is not a valid file or directory"
    exit 1
fi

bash link.sh "$SUBDIR_NAME"

popd > /dev/null


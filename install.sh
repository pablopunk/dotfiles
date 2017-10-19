#!/bin/bash

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# loop in subdirectories
for D in `ls -d1 "$dir"/*/`
do
  bash $D/install.sh
done

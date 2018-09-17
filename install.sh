#!/bin/bash

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# loop in subdirectories
for D in `ls -d1 "$dir"/*/`
do
  if [ -f $D/install.sh ]; then
    bash $D/install.sh
  else
    for F in `ls -1 $D`
    do
      ln -svf $D/$F ~/.$F
    done
  fi
done

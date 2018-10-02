#!/bin/bash

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# loop in subdirectories
for D in `ls -d1 "$dir"/*/`
do
  if [ -f $D/install.sh ]; then
    bash $D/install.sh            # use install.sh if it exists in subdirectory
  else
    for F in `ls -1 $D`
    do
      ln -svf ${D}${F} ~/.$F      # just link the file if there's no install.sh
    done
  fi
done

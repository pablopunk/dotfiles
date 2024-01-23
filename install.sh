#!/bin/bash

# get script directory
dir="$(dirname $(realpath $0))"

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

# set up git hooks
echo "bash install.sh" > .git/hooks/post-merge
chmod +x .git/hooks/post-merge

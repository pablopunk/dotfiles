#!/bin/bash

# get script directory
pushd `dirname .` > /dev/null
dir=`pwd -P`
popd > /dev/null

# loop in subdirectories
for D in `ls -d1 "$dir"/*/`
do
  bash $D/install.sh
done

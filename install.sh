#!/bin/bash

# get script directory
pushd `dirname $0` > /dev/null
dir=`pwd -P`
popd > /dev/null

# loop in subdirectories
for D in `find $dir -mindepth 1 -type d -not -path '*/\.*'`
do
  bash $D/install.sh
done

# link repo
ln -snvf $dir ~/.dotfiles


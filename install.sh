#!/bin/bash

pushd `dirname $0` > /dev/null
dir=`pwd -P`
popd > /dev/null


for D in `find $dir -mindepth 1 -type d`
do
  bash $D/install.sh
done

ln -snvf $dir ~/.dotfiles


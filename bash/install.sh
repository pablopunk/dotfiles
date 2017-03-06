#!/bin/bash

os=`uname`
file_name='bashrc'

if [ ! $os == 'Darwin' ]; then
  file_name='bash_profile'
fi

# get script directory
pushd `dirname $0` > /dev/null
dir=`pwd -P`
popd > /dev/null

# link config file
ln -svf $dir/$file_name ~/.$file_name
file_name='inputrc'
ln -svf $dir/$file_name ~/.$file_name

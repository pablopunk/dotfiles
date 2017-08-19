#!/bin/bash

os=`uname`
file_name='bashrc'

# get script directory
pushd `dirname $0` > /dev/null
dir=`pwd -P`
popd > /dev/null

if [ $os == 'Darwin' ]; then 
  ln -svf $dir/$file_name ~/.bash_profile
else
  # link config file
  ln -svf $dir/$file_name ~/.$file_name
fi

file_name='inputrc'
ln -svf $dir/$file_name ~/.$file_name

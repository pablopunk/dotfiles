#!/bin/bash

file_name='vimrc'

# get script directory
pushd `dirname $0` > /dev/null
dir=`pwd -P`
popd > /dev/null

# link config file
ln -svf $dir/$file_name ~/.$file_name
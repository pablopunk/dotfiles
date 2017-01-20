#!/bin/bash

file_name='hyper.js'

# get script directory
pushd `dirname $0` > /dev/null
dir=`pwd -P`
popd > /dev/null

# link config file
ln -svf $dir/$file_name ~/.$file_name
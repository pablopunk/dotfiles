#!/bin/bash

file_name='tern-config'

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# link config file
ln -svf $dir/$file_name ~/.$file_name

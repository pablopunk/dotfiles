#!/bin/bash

file_name='vimrc'
dir=''

function go_to_script_dir {
  pushd `dirname $0` > /dev/null
  dir=`pwd -P`
  popd > /dev/null
}

function link_config_file {
  ln -svf $dir/$file_name ~/.$file_name
}

go_to_script_dir && link_config_file

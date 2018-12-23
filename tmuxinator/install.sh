
#!/bin/bash

function preinstall {
  rm -rf ~/.tmuxinator
}

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# link config file
preinstall ; ln -svf $dir ~/.tmuxinator

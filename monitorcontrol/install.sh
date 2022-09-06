final_file='~/Library/Preferences/me.guillaumeb.MonitorControl.plist'

function preinstall {
  rm -f "$final_file"
}

# get script directory
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

preinstall && \
  ln -svf $dir/me.guillaumeb.MonitorControl.plist "$final_file"

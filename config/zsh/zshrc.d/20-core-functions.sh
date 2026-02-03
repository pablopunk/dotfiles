# vim:fileencoding=utf-8:ft=zsh:foldmethod=marker
# Core functions used frequently (sourced at startup for immediate availability)
# Rarely-used functions are autoloaded from ~/.zsh/functions/

# Safe rm - moves files to trash instead of deleting
function rm {
  # if it contains -rf then execute command rm
  if [[ "$*" == *"-rf"* ]]; then
    command rm "$@"
    return
  fi
  mkdir -p /tmp/trash
  # get each argument and name it as path-to-file-that-will-be-deleted
  for arg in "$@"; do
    # check if path exists
    if [[ ! -e "$arg" ]]; then
      echo "rm: cannot remove '$arg': No such file or directory"
      continue
    fi
    # example: i run `rm .gitignore` in a folder ~/src then the name will be Users-pablopunk-src-.gitignore so we need to get the full path of the file or directory
    dirname_for_trash=$(realpath "$arg")
    # now replace all / with -
    dirname_for_trash=${dirname_for_trash//\//-}
    # now remove the first -
    dirname_for_trash=${dirname_for_trash#*-}
    # create directory where all versions will live
    mkdir -p "/tmp/trash/$dirname_for_trash"
    # move it there with a specific version (date.now)
    date_now=$(date +%Y-%m-%d_%H-%M-%S)
    mv -f "$arg" "/tmp/trash/$dirname_for_trash/$date_now"
  done
}

# Git commit with message
function gcm {
  git commit -m "$*"
}

# Git add all and commit with message
function gcam {
  if [[ "$*" == *--amend* ]]; then
    git commit -m"$@"
  else
    git add -A
    git commit -m "$*"
  fi
}

# Git commit amend with new message
function gcamm {
  git commit --amend --message "$*"
}

# Clone from personal GitHub and cd into directory
function gclone {
  git clone https://github.com/pablopunk/$1 && cd $1
}

# Copy to clipboard (cross-platform)
function copy {
  [[ "$(uname)" == "Linux" ]] && xsel --clipboard --input
  [[ "$(uname)" == "Darwin" ]] && pbcopy
}

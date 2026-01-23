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
  going_to="/tmp/trash/$USER/$(date +%s%N)"
  mkdir -p "$going_to"
  mv -f "$@" "$going_to"
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

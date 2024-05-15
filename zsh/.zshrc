# vim:fileencoding=utf-8:ft=bash:foldmethod=marker

# Start profiling {{{
if [ -n "${ZSH_DEBUGRC+1}" ]; then
  zmodload zsh/zprof
fi
# }}}

# oh-my-zsh {{{
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(
  macos
  zsh-github-copilot # Requires `gh auth login --web -h github.com`
)
# }}}

# Functions {{{
function gcm {
  git commit -m "$*"
}
function gcam {
  if [[ "$*" == *--amend* ]]; then
    git commit -m"$@"
  else
    git add -A
    git commit -m "$*"
  fi
}
function powersave {
  # linux
  sudo cpufreq-set -g powersave && \
    sudo pm-powersave true
}
function power {
  sudo cpufreq-set -g performance && \
    sudo pm-powersave false
}

function gclone {
  git clone git@github.com:pablopunk/$1 && cd $1
}

function grebase {
  branch="$(git symbolic-ref --short HEAD)"
  git fetch upstream && \
    git rebase upstream/$branch
}

function greset_hard {
  branch="$(git symbolic-ref --short HEAD)"
  git fetch upstream && \
    git reset --hard upstream/$branch
}

function copy {
  [ "$(uname)" == "Linux" ] && xsel --clipboard --input
  [ "$(uname)" == "Darwin" ] && pbcopy
}

function weather {
  curl -s "wttr.in/${1-pontevedra}?format=1"
}

function add_spacer_to_dock {
  defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="small-spacer-tile";}'
  killall Dock
}

function wait_for_docker {
  until docker info &> /dev/null; do
    open /Applications/OrbStack.app
    sleep 1
  done
}

function benchmark_neovim_plugins {
  python3 <(curl -sSL https://raw.githubusercontent.com/hyiltiz/vim-plugins-profile/master/vim-plugins-profile.py) nvim
}

function benchmark_neovim_startuptime {
  hyperfine "nvim --headless +qa" --warmup 5
}

function benchmark_disk {
  tempfile="tempfile"
  echo "Benchmarking disk speed in $PWD"
  echo
  echo "WRITING..."
  sudo dd if=/dev/zero of=$tempfile bs=1G count=1 oflag=dsync > /dev/null
  echo
  echo "READING..."
  sudo dd if=$tempfile of=/dev/zero bs=8k > /dev/null | grep bytes
  sudo rm -f $tempfile
}

function tilt_playwright {
  for service in \
    "signup-api" \
    "localstack" \
    "panel-core" \
    "graph-gateway" \
    "maze-api" \
    "maze-video-recording-api" \
    "maze-webapp" \
    "report-webapp" \
    "testing-webapp" \
    "signup-webapp" \
  ; do
    tilt enable "$service"
    tilt trigger "$service"
  done
}

function tilt {
  [[ "$#" -eq 1 && "$1" == "up" ]] && { wait_for_docker; command tilt up; return; }
  [[ "$#" -ge 2 && "$1" == "trigger" ]] && { shift; for arg in "$@"; do command tilt enable "$arg"; command tilt trigger "$arg"; done; return; }
  command tilt $@
}

function ssh {
  if [[ -z $(which kitten) ]]; then
    command ssh $@
  else
    kitten ssh $@
  fi
}
# }}}

# Aliases {{{
alias g=git
alias gst='git status'
alias gp='git push'
alias gl='git pull'
alias gf='git fetch'
alias glog='git log --oneline --decorate'
alias gd='git diff -w --minimal'
alias gds='git diff -w --staged --minimal'
alias gc='git commit'
alias amend='git commit --amend'
alias gca='git add -A && git commit'
alias gpr='git fetch upstream && git diff -w --minimal upstream/master'
# ls aliases
alias ls='ls -G'
alias ll='ls -lagh'
alias la='ls -a1'
alias l='ls -a1'
alias lr='ls -rt1' # most recent(t) file at the bottom(r) in 1 column(1)
alias t='tree -L 3'
# other
alias prof='PS4='"'"'$(date "+%s.%N ($LINENO) + ")'"'"' bash -x '
alias vi=nvim
alias vvi='nvim -u ~/.vimrc'
alias viu='nvim -u NONE'
alias todo=todo.sh
alias rm-nvim-history='rm ~/.local/state/nvim/swap/*'
alias rm=trash
alias mkidr='mkdir -p'
alias n='npm run'
alias run='npx tsx'
# not in vim but who cares
alias :q='exit'
alias :qa='exit'
alias :x='exit'
alias :xa='exit'
# zoxide
alias cd='z'
# source entry file
alias zs='source ~/.zshrc'
alias bs='source ~/.bashrc'
# }}}

# PATH {{{
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="/usr/local/lib/ruby/gems/2.6.0/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="$HOME/.deno/bin:$PATH"
export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"
export PATH="/Applications/MacVim.app/Contents/bin:$PATH"
export PATH="$HOME/.config/tmux/plugins/t-smart-tmux-session-manager/bin:$PATH"

# }}}

# # `brew shellenv` {{{
# I used to run `eval $(brew shellenv)` but it was too slow
if [ -f /proc/sys/kernel/osrelease ]; then
  # Linuxbrew
  export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew";
  export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar";
  export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew";
  export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin${PATH+:$PATH}";
  export MANPATH="/home/linuxbrew/.linuxbrew/share/man${MANPATH+:$MANPATH}:";
  export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH:-}";
else
  # macOS Homebrew
  export HOMEBREW_PREFIX="/usr/local";
  export HOMEBREW_CELLAR="/usr/local/Cellar";
  export HOMEBREW_REPOSITORY="/usr/local/Homebrew";
  export PATH="/usr/local/bin:/usr/local/sbin${PATH+:$PATH}";
  export MANPATH="/usr/local/share/man${MANPATH+:$MANPATH}:";
  export INFOPATH="/usr/local/share/info:${INFOPATH:-}";
fi
# }}}

# Cargo {{{
export PATH="$HOME/.cargo/bin:$PATH"
function cargo { # lazy load cargo
  [[ -f $HOME/.cargo/env ]] && . "$HOME/.cargo/env"
  command cargo $@
}
# }}}

# Bun.sh {{{
function bun { # lazy load bun
  [[ -f $HOME/.bun/_bun ]] && . "$HOME/.bun/_bun"
  command bun $@
}

function bunx { # lazy load bunx
  [[ -f $HOME/.bun/_bun ]] && . "$HOME/.bun/_bun"
  command bunx $@
}
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# }}}

# Local config (not tracked) {{{
F=$HOME/.additional; [ -f $F ] && . $F
# }}}

# oh-my-zsh config {{{
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSH/oh-my-zsh.sh
bindkey '^ ' zsh_gh_copilot_suggest # ctrl+space to trigger copilot suggestions
setopt PROMPT_SUBST
# }}}

# prompt {{{
eval "$(starship init zsh)"
# NEWLINE=$'\n'
# PROMPT='$(bashy -r)${NEWLINE}%F{yellow}ƛ%f '
# }}}

# TERM {{{
TERM=xterm-256color
# }}}

# auto tmux on vscode and ssh {{{
[ "$TERM_PROGRAM" = "vscode" ] && [ -z "$TMUX" ] && ( tmux a || tmux )
[ ! -z "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && ( tmux a || tmux )
# }}}

# kitty theme (dark/light) {{{
current_theme=$(cat $HOME/.theme 2>/dev/null || echo Dark)
if [ ! -f /proc/sys/kernel/osrelease ]; then
  defaults read -g AppleInterfaceStyle 2>&- >&-
  if [[ $? == 1 ]]
  then
    new_theme=Light
    kitty_theme="Tokyo Night Day"
  else
    new_theme=Dark
    kitty_theme="Tokyo Night"
  fi
  if [[ $current_theme != $new_theme ]]
  then
    kitty +kitten themes $kitty_theme
    echo $new_theme > $HOME/.theme
  fi
fi
# }}}

# movements (alt+arrows) {{{
bindkey "^[[1;3D" backward-word
bindkey "^[[1;3C" forward-word
# }}}

# mise {{{
if hash mise 2>/dev/null; then
  eval "$(mise activate zsh)"
fi
# }}}

# zoxide {{{
if hash zoxide 2>/dev/null; then
  eval "$(zoxide init zsh)"
fi
# }}}

# End profiling {{{
if [ -n "${ZSH_DEBUGRC+1}" ]; then
  zprof
fi
# }}}

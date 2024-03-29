# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/bashrc.pre.bash" ]] && builtin source "$HOME/.fig/shell/bashrc.pre.bash"
source ~/.functions
source ~/.aliases
source ~/.path
F=$HOME/.additional; [ -f $F ] && . $F # aditional local config

# Vars
export EDITOR=nvim
export HISTSIZE=
export HISTFILESIZE=

if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  pre='(ssh:'$(hostname)') '
else
  pre=""
fi

# Use bashy if it exist
if hash bashy 2>/dev/null; then
  export PS1='$pre$(bashy -r) '
else
  export PS1='$pre$ '
fi

# Bash completion
[ -f /etc/bash_completion ] && . /etc/bash_completion
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

# Disable flow control commands (keeps C-s from freezing everything)
stty start undef
stty stop undef


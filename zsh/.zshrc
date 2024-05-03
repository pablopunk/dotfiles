# vim:fileencoding=utf-8:ft=zsh:foldmethod=marker

# oh-my-zsh {{{
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(
  macos
  zsh-github-copilot # Requires `gh auth login --web -h github.com`
)
bindkey '^ ' zsh_gh_copilot_suggest # ctrl+space to trigger copilot suggestions
# }}}

# modular config {{{
source ~/.functions
source ~/.aliases
source ~/.path
F=$HOME/.additional; [ -f $F ] && . $F # aditional local config
# }}}

# oh-my-zsh config {{{
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSH/oh-my-zsh.sh
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
# [ "$TERM_PROGRAM" = "vscode" ] && [ -z "$TMUX" ] && ( tmux a || tmux )
[ ! -z "$SSH_CONNECTION" ] && [ -z "$TMUX" ] && ( tmux a || tmux )
# }}}

# kitty theme (dark/light) {{{
current_theme=$(cat $HOME/.theme 2>/dev/null || echo Dark)
if [[ $(uname) == "Darwin" ]]; then
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

# bun completions {{{
[ -s "~/.bun/_bun" ] && source "~/.bun/_bun"
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


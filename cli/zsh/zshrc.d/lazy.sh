# vim:fileencoding=utf-8:ft=bash:foldmethod=marker

# mise {{{
if hash mise 2>/dev/null; then
  eval "$(mise activate zsh)"
fi
# mise }}}

# zoxide {{{
if hash zoxide 2>/dev/null; then
  eval "$(zoxide init zsh)"
fi
# zoxide }}}


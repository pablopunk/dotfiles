# vim:fileencoding=utf-8:ft=bash:foldmethod=marker

# cargo {{{
export PATH="$HOME/.cargo/bin:$PATH"
function cargo { # lazy load cargo
  [[ -f $HOME/.cargo/env ]] && . "$HOME/.cargo/env"
  command cargo $@
}
# cargo }}}

# bun {{{
function bunx {
  [[ -f $HOME/.bun/_bun ]] && . "$HOME/.bun/_bun"
  command bunx $@
}
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
# bun completions
[ -s "/Users/pablopunk/.bun/_bun" ] && source "/Users/pablopunk/.bun/_bun"
# bun }}}

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


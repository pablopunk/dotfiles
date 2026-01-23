if (( $+commands[zoxide] )); then
  _zoxide_cache="$HOME/.cache/zsh/zoxide.zsh"
  if [[ ! -f "$_zoxide_cache" || "$commands[zoxide]" -nt "$_zoxide_cache" ]]; then
    mkdir -p "${_zoxide_cache:h}"
    zoxide init zsh > "$_zoxide_cache"
  fi
  source "$_zoxide_cache"
fi


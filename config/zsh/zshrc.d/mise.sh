if (( $+commands[mise] )); then
  _mise_cache="$HOME/.cache/zsh/mise.zsh"
  if [[ ! -f "$_mise_cache" || "$commands[mise]" -nt "$_mise_cache" ]]; then
    mkdir -p "${_mise_cache:h}"
    mise activate zsh > "$_mise_cache"
  fi
  source "$_mise_cache"
fi


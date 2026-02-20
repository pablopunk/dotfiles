# vim:fileencoding=utf-8:ft=zsh:foldmethod=marker
# OpenCode configuration

# Server port for tmux multi-agent pane support
export OPENCODE_PORT=4096

# ============================================================
# Profile-based OpenCode launcher
# ============================================================

oc() {
  local current_dir="${PWD}"

  if [[ "${current_dir}" == "${HOME}/src/maze"* ]]; then
    ocw "$@"
  else
    ocp "$@"
  fi
}

occ() {
  oc --continue
}

ocp() {
  env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GOOGLE_API_KEY -u OPENROUTER_API_KEY -u OPENCODE_API_KEY \
  opencode "$@"
}

ocw() {
  local xdg_config="${HOME}/.config-work"
  local xdg_data="${HOME}/.local/share-work"

  mkdir -p "${xdg_config}/opencode"
  mkdir -p "${xdg_data}/opencode"

  env -u ANTHROPIC_API_KEY -u OPENAI_API_KEY -u GOOGLE_API_KEY -u OPENROUTER_API_KEY -u OPENCODE_API_KEY \
  XDG_CONFIG_HOME="${xdg_config}" \
  XDG_DATA_HOME="${xdg_data}" \
  opencode "$@"
}

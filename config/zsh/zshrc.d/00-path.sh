# vim:fileencoding=utf-8:ft=zsh:foldmethod=marker
# Consolidated PATH configuration
# Using zsh path array for efficiency (single operation vs multiple exports)

path=(
  # User binaries
  $HOME/.opencode/bin
  $HOME/.cargo/bin
  $HOME/.bun/bin
  $HOME/.deno/bin
  $HOME/.lmstudio/bin
  $HOME/.bin
  $HOME/.local/bin
  $HOME/.console-ninja/.bin
  
  # Tmux session manager
  $HOME/.config/tmux/plugins/t-smart-tmux-session-manager/bin
  
  # macOS Applications (N flag: null_glob - no error if doesn't exist)
  /Applications/MacVim.app/Contents/bin(N)
  /Applications/Sublime\ Text.app/Contents/SharedSupport/bin(N)
  
  # System paths
  /usr/local/bin
  /usr/local/opt/ruby/bin
  /usr/local/lib/ruby/gems/2.6.0/bin
  
  # Existing path
  $path
)

# Remove duplicates
typeset -U path

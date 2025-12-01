# Completion configuration
zstyle ':completion:*' menu select                       # Interactive menu selection
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'     # Case-insensitive matching
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}   # Colored completion lists
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
setopt AUTO_MENU           # Show completion menu on tab press
setopt COMPLETE_IN_WORD    # Complete from cursor position
setopt ALWAYS_TO_END       # Move cursor to end after completion

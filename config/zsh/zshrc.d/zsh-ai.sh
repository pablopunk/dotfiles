unsetopt noclobber # Do overwrite files with >
export ZSH_AI_ANTHROPIC_MODEL="claude-haiku-4-5"  # (default)
export ZSH_AI_ANTHROPIC_URL="https://api.anthropic.com/v1/messages"  # (default)
source $(brew --prefix)/share/zsh-ai/zsh-ai.plugin.zsh

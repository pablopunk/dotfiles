# vim:fileencoding=utf-8:ft=zsh
unsetopt noclobber  # Allow overwriting files with >
export ZSH_AI_ANTHROPIC_MODEL="claude-haiku-4-5"
export ZSH_AI_ANTHROPIC_URL="https://api.anthropic.com/v1/messages"

# Hardcoded brew prefix for speed (avoids ~22ms `brew --prefix` call)
# Update this path if homebrew location changes
if [[ -f /opt/homebrew/share/zsh-ai/zsh-ai.plugin.zsh ]]; then
  source /opt/homebrew/share/zsh-ai/zsh-ai.plugin.zsh
elif [[ -f /home/linuxbrew/.linuxbrew/share/zsh-ai/zsh-ai.plugin.zsh ]]; then
  source /home/linuxbrew/.linuxbrew/share/zsh-ai/zsh-ai.plugin.zsh
fi

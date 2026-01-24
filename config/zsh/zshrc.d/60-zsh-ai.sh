# vim:fileencoding=utf-8:ft=zsh
unsetopt noclobber  # Allow overwriting files with >
export ZSH_AI_PROVIDER="openai"
export ZSH_AI_OPENAI_MODEL="gpt-4.1-nano"

# Hardcoded brew prefix for speed (avoids ~22ms `brew --prefix` call)
# Update this path if homebrew location changes
if [[ -f /opt/homebrew/share/zsh-ai/zsh-ai.plugin.zsh ]]; then
  source /opt/homebrew/share/zsh-ai/zsh-ai.plugin.zsh
elif [[ -f /home/linuxbrew/.linuxbrew/share/zsh-ai/zsh-ai.plugin.zsh ]]; then
  source /home/linuxbrew/.linuxbrew/share/zsh-ai/zsh-ai.plugin.zsh
fi

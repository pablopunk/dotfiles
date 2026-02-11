#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check if dotfiles are already installed
if [[ -d "$HOME/.dotfiles" ]]; then
  echo -e "${GREEN}✓${NC} Dotfiles already installed"
  exit 0
fi

# Install dot
DOT_BIN="$HOME/.local/bin/dot"
if [[ ! -f "$DOT_BIN" ]]; then
  curl -fsSL https://raw.githubusercontent.com/pablopunk/dot/main/scripts/install.sh | bash
fi
export PATH="$HOME/.local/bin:$PATH"

# Clone dotfiles
git clone https://github.com/pablopunk/dotfiles.git ~/.dotfiles > /dev/null 2>&1
cd "$HOME/.dotfiles"

# Show available profiles
echo "Available profiles:"
"$DOT_BIN" --profiles || {
  echo -e "${RED}✗${NC} Failed to list profiles"
  exit 1
}

echo ""
read -p "Profiles to install (empty for default): " -r profiles_input

# Run dot
if [[ -n "$profiles_input" ]]; then
  "$DOT_BIN" $profiles_input
else
  "$DOT_BIN"
fi

# Set zsh as default
zsh_path=$(command -v zsh)
chsh -s "$zsh_path" 2>/dev/null || true

echo -e "${GREEN}✓${NC} Done"
exec zsh -l

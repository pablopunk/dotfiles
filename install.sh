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
if ! command -v dot &> /dev/null; then
  curl -fsSL https://raw.githubusercontent.com/pablopunk/dot/main/scripts/install.sh | bash
  # dot might have been installed to ~/.local/bin, add to PATH
  export PATH="$HOME/.local/bin:$PATH"
fi

# Clone dotfiles
git clone https://github.com/pablopunk/dotfiles.git ~/.dotfiles > /dev/null 2>&1
cd "$HOME/.dotfiles"

# Show available profiles
echo "Available profiles:"
dot --profiles 2>/dev/null || exit 1

echo ""
read -p "Profiles to install (empty for default): " -r profiles_input

# Run dot
dot_cmd="dot"
[[ -n "$profiles_input" ]] && dot_cmd="dot $profiles_input"
$dot_cmd

# Set zsh as default
zsh_path=$(command -v zsh)
chsh -s "$zsh_path" 2>/dev/null || true

echo -e "${GREEN}✓${NC} Done"
exec zsh -l

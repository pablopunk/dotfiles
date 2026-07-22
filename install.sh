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

# Install Homebrew on macOS
if [[ $(uname -s) == "Darwin" ]]; then
  if ! command -v brew &> /dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# Clone dotfiles
git clone https://github.com/pablopunk/dotfiles.git ~/.dotfiles > /dev/null 2>&1
cd "$HOME/.dotfiles"

"$DOT_BIN" -i mise # install mise first cause bun is needed for other packages
"$DOT_BIN"

# Set zsh as default
zsh_path=$(command -v zsh)
chsh -s "$zsh_path" 2>/dev/null || true

echo -e "${GREEN}✓${NC} Done"
exec zsh -l

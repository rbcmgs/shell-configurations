#!/usr/bin/env bash
# Sets up Starship + bash config on Linux/macOS by symlinking this repo's files.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%s)"
    echo "Backed up existing $dest"
  fi
  ln -sfn "$src" "$dest"
  echo "Linked $dest -> $src"
}

if ! command -v starship >/dev/null 2>&1; then
  echo "Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Install Node.js LTS on Debian/Ubuntu if missing (required for npm-based Copilot CLI install).
if ! command -v node >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    echo "Installing Node.js LTS (Debian/Ubuntu)..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
  else
    echo "Node.js is not installed. Install Node.js LTS, then rerun this script."
  fi
fi

# Install GitHub Copilot CLI if missing.
if ! command -v copilot >/dev/null 2>&1; then
  if command -v npm >/dev/null 2>&1; then
    echo "Installing GitHub Copilot CLI..."
    npm install -g @github/copilot
  else
    echo "npm is not available. Install npm, then run: npm install -g @github/copilot"
  fi
fi

link "$repo/.config/starship.toml" "$HOME/.config/starship.toml"
link "$repo/.bashrc" "$HOME/.bashrc"

if command -v copilot >/dev/null 2>&1; then
  mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/copilot"
  copilot completion bash > "${XDG_CACHE_HOME:-$HOME/.cache}/copilot/completion.bash" 2>/dev/null || true
fi

echo "Done. Install a Nerd Font, restart your shell, and run 'copilot login' if needed."
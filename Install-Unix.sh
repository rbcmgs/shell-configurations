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

link "$repo/.config/starship.toml" "$HOME/.config/starship.toml"
link "$repo/.bashrc" "$HOME/.bashrc"

echo "Done. Install a Nerd Font and restart your shell."
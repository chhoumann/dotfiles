#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${1:?dotfiles dir required}"

echo "Installing packages from Brewfile..."
brew bundle --file="${DOTFILES_DIR}/Brewfile"

#!/usr/bin/env bash

set -euo pipefail

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ -r "${ZINIT_HOME}/zinit.zsh" ]]; then
  echo "Zinit already installed"
  exit 0
fi

echo "Installing Zinit..."
mkdir -p "$(dirname "$ZINIT_HOME")"
git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

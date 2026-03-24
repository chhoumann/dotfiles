#!/usr/bin/env bash

set -euo pipefail

echo "Installing Homebrew..."
if command -v brew >/dev/null 2>&1; then
  echo "Homebrew already installed"
  brew update
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

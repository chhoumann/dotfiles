#!/usr/bin/env bash

set -euo pipefail

echo "Installing and configuring Vite+..."
if [[ ! -x "$HOME/.vite-plus/bin/vp" ]]; then
  curl -fsSL https://vite.plus | bash
fi

eval "$("$HOME/.vite-plus/bin/vp" env print)"
vp env setup
vp env on
vp env default lts
vp env install

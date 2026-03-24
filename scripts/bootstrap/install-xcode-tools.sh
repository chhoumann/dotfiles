#!/usr/bin/env bash

set -euo pipefail

echo "Installing Xcode Command Line Tools..."
if xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools already installed"
  exit 0
fi

xcode-select --install
exit 20

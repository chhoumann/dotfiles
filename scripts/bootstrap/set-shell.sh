#!/usr/bin/env bash

set -euo pipefail

desired_shell="/bin/zsh"
if [[ "$SHELL" == "$desired_shell" ]]; then
  echo "Shell already set to $desired_shell"
  exit 0
fi

if ! grep -q "$desired_shell" /etc/shells; then
  echo "$desired_shell" | sudo tee -a /etc/shells >/dev/null
fi

chsh -s "$desired_shell"
echo "Default shell set to $desired_shell"

#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${1:?dotfiles dir required}"
bash "$DOTFILES_DIR/macos/enable-touchid-sudo.sh"

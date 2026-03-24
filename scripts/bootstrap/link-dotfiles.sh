#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${1:?dotfiles dir required}"
shift

cd "$DOTFILES_DIR"
"$DOTFILES_DIR/install" "$@"

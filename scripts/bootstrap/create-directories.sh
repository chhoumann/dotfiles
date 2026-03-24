#!/usr/bin/env bash

set -euo pipefail

for dir in \
  "$HOME/.config" \
  "$HOME/Developer" \
  "$HOME/Pictures/Screenshots"
do
  mkdir -p "$dir"
done

echo "Ensured core directories exist"

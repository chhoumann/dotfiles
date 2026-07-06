#!/usr/bin/env bash
# Dump one line per installed package: "<ecosystem> <name> <version>".
# The tgall wrapper snapshots this before and after a topgrade run and
# update-digest.sh diffs the two. Read-only, fast, and tolerant: missing
# package managers or a failing lister just drop out of the manifest.
set -uo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

{
  if have brew; then
    brew list --versions 2>/dev/null | awk '{ print "brew", $1, $NF }'
    brew list --cask --versions 2>/dev/null | awk '{ print "cask", $1, $NF }'
  fi

  if have cargo; then
    cargo install --list 2>/dev/null |
      awk '/^[^ ].* v[0-9]/ { v = $2; sub(/^v/, "", v); sub(/:$/, "", v); print "cargo", $1, v }'
  fi

  if have uv; then
    uv --version 2>/dev/null | awk '{ print "toolchain uv", $2 }'
    uv tool list 2>/dev/null |
      awk '/^[A-Za-z0-9._-]+ v[0-9]/ { v = $2; sub(/^v/, "", v); print "uv-tool", $1, v }'
  fi

  if have bun; then
    bun --version 2>/dev/null | awk '{ print "toolchain bun", $1 }'
    bun pm ls -g 2>/dev/null |
      sed -nE 's/^[^A-Za-z0-9@]*([^ ]+)@([0-9][^ ]*)$/bun-global \1 \2/p'
  fi

  if have code; then
    code --list-extensions --show-versions 2>/dev/null |
      awk -F@ 'NF == 2 { print "vscode-ext", $1, $2 }'
  fi

  if have gh; then
    gh extension list 2>/dev/null |
      awk -F'\t' 'NF >= 3 { v = $3; sub(/^v/, "", v); print "gh-ext", $2, v }'
  fi

  have rustc && rustc --version 2>/dev/null | awk '{ print "toolchain rustc", $2 }'
  have node && node --version 2>/dev/null | awk '{ sub(/^v/, ""); print "toolchain node", $0 }'
  have claude && claude --version 2>/dev/null | awk '{ print "toolchain claude-code", $1 }'
} | sort

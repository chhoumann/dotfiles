#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

pass() {
  printf 'PASS %s\n' "$1"
}

warn() {
  printf 'WARN %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1"
  failures=$((failures + 1))
}

check_symlink_into_repo() {
  local path="$1"
  local label="$2"

  if [[ ! -L "$path" ]]; then
    fail "$label is not a symlink"
    return
  fi

  local target
  target="$(readlink "$path")"
  if [[ "$target" != "$DOTFILES_DIR/"* ]]; then
    fail "$label does not point into dotfiles"
    return
  fi

  if [[ ! -e "$path" ]]; then
    fail "$label is a broken symlink"
    return
  fi

  pass "$label linked into dotfiles"
}

if command -v brew >/dev/null 2>&1; then
  pass "homebrew installed"
else
  fail "homebrew installed"
fi

if brew --prefix >/dev/null 2>&1; then
  pass "homebrew usable"
else
  fail "homebrew usable"
fi

if [[ -x "$HOME/.vite-plus/bin/vp" ]]; then
  pass "vite+ binary present"
else
  fail "vite+ binary present"
fi

if [[ -f "$HOME/.vite-plus/env" ]]; then
  pass "vite+ env file present"
else
  fail "vite+ env file present"
fi

node_info="$(env -i HOME="$HOME" USER="${USER:-}" LOGNAME="${LOGNAME:-}" SHELL=/bin/zsh PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin /bin/zsh -lic 'printf "%s\n%s\n%s\n%s\n" "$(which node)" "$(which npm)" "$(node -v)" "$(npm -v)"' 2>/dev/null || true)"
node_path="$(printf '%s\n' "$node_info" | sed -n '1p')"
npm_path="$(printf '%s\n' "$node_info" | sed -n '2p')"

if [[ "$node_path" == "$HOME/.vite-plus/bin/"* ]]; then
  pass "node resolves via Vite+"
else
  fail "node resolves via Vite+"
fi

if [[ "$npm_path" == "$HOME/.vite-plus/bin/"* ]]; then
  pass "npm resolves via Vite+"
else
  fail "npm resolves via Vite+"
fi

check_symlink_into_repo "$HOME/.zshrc" "~/.zshrc"
check_symlink_into_repo "$HOME/.zprofile" "~/.zprofile"
check_symlink_into_repo "$HOME/.zshenv" "~/.zshenv"
check_symlink_into_repo "$HOME/.npmrc" "~/.npmrc"
check_symlink_into_repo "$HOME/.config/topgrade.toml" "~/.config/topgrade.toml"
check_symlink_into_repo "$HOME/.config/uv/uv.toml" "~/.config/uv/uv.toml"

if [[ -e "$HOME/.zprofile.local" ]]; then
  if [[ -r "$HOME/.zprofile.local" ]]; then
    pass "~/.zprofile.local present"
  else
    fail "~/.zprofile.local is not readable"
  fi
else
  warn "~/.zprofile.local missing (optional)"
fi

if [[ -x "$DOTFILES_DIR/dotbot/bin/dotbot" ]]; then
  pass "dotbot checkout usable"
else
  fail "dotbot checkout usable"
fi

for config in default.conf.yaml mac.conf.yaml apps.conf.yaml; do
  if [[ -f "$DOTFILES_DIR/$config" ]]; then
    pass "$config present"
  else
    fail "$config present"
  fi
done

if [[ $failures -gt 0 ]]; then
  exit 1
fi

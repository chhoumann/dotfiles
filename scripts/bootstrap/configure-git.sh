#!/usr/bin/env bash

set -euo pipefail

git_name=""
git_email=""
non_interactive=false

while (($#)); do
  case "$1" in
    --name)
      shift
      git_name="${1:-}"
      ;;
    --email)
      shift
      git_email="${1:-}"
      ;;
    --non-interactive)
      non_interactive=true
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
  shift
done

if ! command -v git >/dev/null 2>&1; then
  echo "Git is not installed; skipping git configuration"
  exit 0
fi

current_name="$(git config --global user.name || true)"
current_email="$(git config --global user.email || true)"
local_gitconfig="${HOME}/.gitconfig.local"

if [[ -z "$current_name" ]]; then
  if [[ -n "$git_name" ]]; then
    git config --file "$local_gitconfig" user.name "$git_name"
  elif ! $non_interactive && [[ -t 0 ]]; then
    read -r -p "Enter your full name for git: " git_name
    [[ -n "$git_name" ]] && git config --file "$local_gitconfig" user.name "$git_name"
  else
    echo "Skipping git user.name; no value supplied"
  fi
fi

if [[ -z "$current_email" ]]; then
  if [[ -n "$git_email" ]]; then
    git config --file "$local_gitconfig" user.email "$git_email"
  elif ! $non_interactive && [[ -t 0 ]]; then
    read -r -p "Enter your email for git: " git_email
    [[ -n "$git_email" ]] && git config --file "$local_gitconfig" user.email "$git_email"
  else
    echo "Skipping git user.email; no value supplied"
  fi
fi

if command -v gh >/dev/null 2>&1; then
  gh auth setup-git 2>/dev/null || true
fi

echo "Git configuration complete"

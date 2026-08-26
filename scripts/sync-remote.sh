#!/usr/bin/env bash
# Make a Linux agent box match this machine's dev/agent setup.
#
#   scripts/sync-remote.sh <ssh-host>     # e.g. sync-remote.sh agents-fsn1
#
# Two phases, both idempotent:
#   1. Synchronize the private canonical skills repository through Git and
#      reconcile this Mac from it.
#   2. Push this repo, clone-or-pull both repositories on the box, run the
#      Linux bootstrap, and verify host health.
set -euo pipefail

host="${1:?usage: sync-remote.sh <ssh-host>}"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_URL="https://github.com/chhoumann/dotfiles.git"
SKILLS_REPO_URL="https://github.com/chhoumann/skills.git"
SKILLS_DIR="$HOME/Developer/skills"

step() { printf '\n==> %s\n' "$1"; }

step "synchronize skills repository"
if [[ ! -d "$SKILLS_DIR/.git" ]]; then
  echo "missing canonical skills Git repository: $SKILLS_DIR" >&2
  exit 1
fi
if [[ -n "$(git -C "$SKILLS_DIR" status --porcelain)" ]]; then
  echo "skills repository is dirty; commit or discard its changes before syncing" >&2
  exit 1
fi
ssh "$host" '
  set -euo pipefail
  skills_dir="$HOME/Developer/skills"
  if [ -d "$skills_dir/.git" ]; then
    if [ -n "$(git -C "$skills_dir" status --porcelain)" ]; then
      echo "remote skills repository is dirty; commit or discard its changes before syncing" >&2
      exit 1
    fi
    git -C "$skills_dir" push origin HEAD
  elif [ -e "$skills_dir" ]; then
    echo "remote skills source exists but is not a Git repository: $skills_dir" >&2
    exit 1
  fi
'
git -C "$SKILLS_DIR" pull --ff-only
git -C "$SKILLS_DIR" push origin HEAD
"$SKILLS_DIR/scripts/bootstrap-skills.sh"

step "push dotfiles"
if [[ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]]; then
  echo "WARN: dotfiles repo is dirty; the box only receives committed, pushed state" >&2
fi
git -C "$DOTFILES_DIR" push

step "bootstrap $host"
git_name="$(git -C "$DOTFILES_DIR" config user.name || true)"
git_email="$(git -C "$DOTFILES_DIR" config user.email || true)"
ssh "$host" bash -s -- "$(printf '%q' "$REPO_URL")" "$(printf '%q' "$SKILLS_REPO_URL")" "$(printf '%q' "$git_name")" "$(printf '%q' "$git_email")" <<'REMOTE'
set -euo pipefail
repo_url="$1"; skills_repo_url="$2"; git_name="$3"; git_email="$4"
if [ -d "$HOME/dotfiles/.git" ]; then
  git -C "$HOME/dotfiles" pull --ff-only
else
  git clone "$repo_url" "$HOME/dotfiles"
fi
skills_dir="$HOME/Developer/skills"
if [ -d "$skills_dir/.git" ]; then
  git -C "$skills_dir" pull --ff-only
elif [ -e "$skills_dir" ]; then
  echo "remote skills source exists but is not a Git repository: $skills_dir" >&2
  exit 1
else
  mkdir -p "$HOME/Developer"
  git clone "$skills_repo_url" "$skills_dir"
fi
"$HOME/dotfiles/scripts/bootstrap-linux.sh" --git-name "$git_name" --git-email "$git_email"
"$skills_dir/scripts/bootstrap-agents-fsn1.sh"
REMOTE

step "verify skills"
ssh "$host" 'skills-sync doctor --source "$HOME/Developer/skills" --json'

printf '\nDone. If the agent CLIs are not logged in yet, run on the box:\n'
printf '  claude        # Claude Code login\n'
printf '  codex login   # Codex login\n'

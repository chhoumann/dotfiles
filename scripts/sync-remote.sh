#!/usr/bin/env bash
# Make a Linux agent box match this machine's dev/agent setup.
#
#   scripts/sync-remote.sh <ssh-host>     # e.g. sync-remote.sh agents-fsn1
#
# Three phases, all idempotent:
#   1. Push this repo, then clone-or-pull it on the box and run
#      scripts/bootstrap-linux.sh there (git identity is read from the
#      local git config and passed along).
#   2. rsync ~/.agents/skills to the box. The skills repo is private and
#      agent boxes deliberately hold no GitHub credentials, so skills
#      travel over SSH instead of git.
#   3. Recreate the ~/.claude/skills layout on the box: relative symlinks
#      into ~/.agents/skills, plus the local-only skill directories.
#      Mac-only skills are excluded below.
set -euo pipefail

host="${1:?usage: sync-remote.sh <ssh-host>}"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_URL="https://github.com/chhoumann/dotfiles.git"

# Skills that only make sense on the Mac (local apps, local databases,
# repos that don't exist on the box).
SKILL_EXCLUDES=(use-spark aside-browser)

skill_excluded() {
  local name="$1" ex
  for ex in "${SKILL_EXCLUDES[@]}"; do
    [[ "$name" == "$ex" ]] && return 0
  done
  return 1
}

step() { printf '\n==> %s\n' "$1"; }

step "push dotfiles"
if [[ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]]; then
  echo "WARN: dotfiles repo is dirty; the box only receives committed, pushed state" >&2
fi
git -C "$DOTFILES_DIR" push

step "bootstrap $host"
git_name="$(git -C "$DOTFILES_DIR" config user.name || true)"
git_email="$(git -C "$DOTFILES_DIR" config user.email || true)"
ssh "$host" bash -s -- "$(printf '%q' "$REPO_URL")" "$(printf '%q' "$git_name")" "$(printf '%q' "$git_email")" <<'REMOTE'
set -euo pipefail
repo_url="$1"; git_name="$2"; git_email="$3"
if [ -d "$HOME/dotfiles/.git" ]; then
  git -C "$HOME/dotfiles" pull --ff-only
else
  git clone "$repo_url" "$HOME/dotfiles"
fi
"$HOME/dotfiles/scripts/bootstrap-linux.sh" --git-name "$git_name" --git-email "$git_email"
REMOTE

step "sync ~/.agents/skills"
ssh "$host" 'mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"'
rsync -a --delete --info=stats1 "$HOME/.agents/skills/" "$host:.agents/skills/"

step "sync ~/.claude/skills layout"
# Walk the local layout once and mirror it: shared skills become relative
# symlinks (recreated remotely), local-only directories are rsynced.
# Symlinks pointing outside ~/.agents/skills (project repos like henosia)
# are skipped - their targets don't exist on the box.
links=()
for path in "$HOME/.claude/skills"/*; do
  name="$(basename "$path")"
  skill_excluded "$name" && { echo "skip (mac-only): $name"; continue; }
  if [[ -L "$path" ]]; then
    target="$(readlink "$path")"
    if [[ "$target" == ../../.agents/skills/* ]]; then
      links+=("$name")
    else
      echo "skip (target not synced): $name -> $target"
    fi
  elif [[ -d "$path" ]]; then
    rsync -a --delete "$path/" "$host:.claude/skills/$name/"
    echo "synced dir: $name"
  fi
done
# ${links[@]+...} keeps `set -u` happy on the empty array under bash 3.2
# (macOS's /bin/bash), where a plain "${links[@]}" would be an unbound error.
printf '%s\n' ${links[@]+"${links[@]}"} | ssh "$host" '
  set -euo pipefail
  mkdir -p "$HOME/.claude/skills"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    ln -sfn "../../.agents/skills/$name" "$HOME/.claude/skills/$name"
  done
  echo "linked $(ls -1 "$HOME/.claude/skills" | wc -l) skills total"
'

printf '\nDone. If the agent CLIs are not logged in yet, run on the box:\n'
printf '  claude        # Claude Code login\n'
printf '  codex login   # Codex login\n'

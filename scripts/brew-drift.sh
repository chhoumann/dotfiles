#!/usr/bin/env bash
# Report drift between what brew has installed and the dotfiles Brewfile.
#
# Read-only: never installs, uninstalls, or rewrites anything - updating
# the Brewfile stays a manual step.
#
# Machine-local packages that aren't part of the portable setup go in
# Brewfile.local (same syntax, gitignored); they then stop showing up
# as drift.
#
# Compares name sets, not versions, so merely-outdated packages are never
# reported and the result is the same before or after `brew upgrade`.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$DOTFILES_DIR/Brewfile"
LOCAL_BREWFILE="$DOTFILES_DIR/Brewfile.local"

# Strip tap qualifiers (openclaw/tap/gogcli -> gogcli) so Brewfile entries
# match `brew list` output; drop blanks, sort, dedup.
names() { awk -F/ 'NF { print $NF }' | sort -u; }

# All entries of one type across Brewfile and (if present) Brewfile.local.
tracked() {
  local type="$1"
  brew bundle list --file="$BREWFILE" --"$type" 2>/dev/null || true
  if [[ -f "$LOCAL_BREWFILE" ]]; then
    brew bundle list --file="$LOCAL_BREWFILE" --"$type" 2>/dev/null || true
  fi
}

# Lines present in $1 but not in $2 (both newline-separated sets).
diff_sets() { comm -23 <(grep . <<<"$1" || true) <(grep . <<<"$2" || true); }

installed_formulae="$(brew list --installed-on-request | names)"
installed_casks="$(brew list --cask | names)"
installed_taps="$(brew tap | sort -u)"

tracked_formulae="$(tracked formula | names)"
tracked_casks="$(tracked cask | names)"
tracked_taps="$(tracked tap | sort -u)"

drift=0

report() {
  local heading="$1" fmt="$2" items="$3"
  [[ -z "$items" ]] && return 0
  if (( drift == 0 )); then
    printf 'Brewfile drift (%s)\n' "$BREWFILE"
  fi
  drift=1
  printf '\n%s\n' "$heading"
  while IFS= read -r name; do
    # shellcheck disable=SC2059 # fmt is a controlled template
    printf "  $fmt\n" "$name"
  done <<<"$items"
}

report 'Installed but untracked taps - add to Brewfile or Brewfile.local (machine-local):' \
  'tap "%s"' "$(diff_sets "$installed_taps" "$tracked_taps")"
report 'Installed but untracked formulae - add to Brewfile or Brewfile.local (machine-local):' \
  'brew "%s"' "$(diff_sets "$installed_formulae" "$tracked_formulae")"
report 'Installed but untracked casks - add to Brewfile or Brewfile.local (machine-local):' \
  'cask "%s"' "$(diff_sets "$installed_casks" "$tracked_casks")"

report 'Tracked but not installed - run "brew bundle install" or delete the entry:' \
  'tap %s' "$(diff_sets "$tracked_taps" "$installed_taps")"
report 'Tracked but not installed - run "brew bundle install" or delete the entry:' \
  'formula %s' "$(diff_sets "$tracked_formulae" "$installed_formulae")"
report 'Tracked but not installed - run "brew bundle install" or delete the entry:' \
  'cask %s' "$(diff_sets "$tracked_casks" "$installed_casks")"

if (( drift )); then
  printf '\nNothing was changed; untracked lines above are ready to paste.\n'
else
  echo 'Brewfile is in sync with installed packages.'
fi

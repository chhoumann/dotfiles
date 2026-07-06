#!/usr/bin/env bash
# Diff two pkg-manifest.sh snapshots and, when versions changed, generate an
# AI digest of the bumps that actually matter on this machine: breaking or
# behavior changes touching real aliases/workflows, notable new capabilities,
# and security fixes - with release notes as the source, not guesswork.
#
# Digests are machine-local; they live under ~/.local/state/tgall/digests,
# not in the repo.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage="usage: update-digest.sh <before-manifest> <after-manifest>"
before="${1:?$usage}"
after="${2:?$usage}"
state="${TGALL_STATE:-$HOME/.local/state/tgall}"

changes="$(awk '
  NR == FNR { old[$1 " " $2] = $3; next }
  {
    key = $1 " " $2
    if (!(key in old))            print $1, $2, "(new)", "->", $3
    else if (old[key] != $3)      print $1, $2, old[key], "->", $3
    delete old[key]
  }
  END { for (k in old) print k, old[k], "->", "(removed)" }
' "$before" "$after" | sort)"

if [[ -z "$changes" ]]; then
  echo 'No package changes detected - skipping digest.'
  exit 0
fi

count="$(wc -l <<<"$changes" | tr -d ' ')"
printf '%s package change(s):\n%s\n\n' "$count" "$changes"

# Backend: codex (gpt-5.5) by default - digest generation is bulk analysis -
# with claude as fallback. Override via TGALL_DIGEST_BACKEND=claude|codex.
backend="${TGALL_DIGEST_BACKEND:-}"
if [[ -z "$backend" ]]; then
  if command -v codex >/dev/null 2>&1; then backend=codex
  elif command -v claude >/dev/null 2>&1; then backend=claude
  else
    echo 'Neither codex nor claude CLI found - skipping AI digest.'
    exit 0
  fi
fi

# Codex's read-only sandbox blocks network for shell commands, so release
# notes must come through its server-side web search tool. Claude gets an
# allowlist of note-fetching tools instead.
if [[ "$backend" == codex ]]; then
  # shellcheck disable=SC2016 # backticks here are markdown in the prompt
  tool_guidance='- For those (aim for 3-8), read the actual release notes via web search
  (e.g. "lazygit 0.63.0 release notes", or the GitHub releases page for the
  project). Local shell commands have no network access, so do not try
  `gh` or `curl`; `brew info --json=v2 <formula>` works offline to reveal
  an upstream repo URL.'
else
  # shellcheck disable=SC2016 # backticks here are markdown in the prompt
  tool_guidance='- For those (aim for 3-8), read the actual release notes:
  `gh release view <tag> --repo <owner/repo>` or
  `gh api repos/<owner/repo>/releases`; `brew info --json=v2 <formula>`
  reveals the upstream repo; WebFetch a changelog when it is not on GitHub.'
fi

# Context that makes the digest personal: what this machine actually runs.
aliases="$(grep -E '^[[:space:]]*alias [A-Za-z]' "$DOTFILES_DIR/zshrc" || true)"
top_commands="$(atuin stats --count 40 2>/dev/null |
  sed $'s/\x1b\[[0-9;]*m//g' | sed -E 's/^\[[^]]*\][[:space:]]*//' |
  grep -E '^[0-9]' || true)"

prompt="$(cat <<EOF
You are writing a post-update digest for a developer's Mac after a package
update run (topgrade). Below are the version changes plus context about how
this machine is actually used. Your job: surface the handful of changes that
matter to this specific user, concretely, and let the rest go.

## Version changes (ecosystem package old -> new)
$changes

## Shell aliases defined on this machine
$aliases

## Most-used commands from shell history (count, command)
$top_commands

## Instructions
- Pick the changes worth investigating: tools that appear in the aliases or
  top commands, major/minor version jumps (not patch noise), and
  security-sensitive packages (openssl, gnupg, git, ssh/curl-alikes).
  Transitive C libraries (glib, libtiff, pango, ...) are routine unless you
  know of a CVE.
$tool_guidance
- Write GitHub-flavored markdown, at most ~40 lines:
  - \`## Worth knowing\` - ranked list. Prefix each item with ⚠ (breaking or
    behavior change that touches this user's aliases/flags/workflows - name
    the exact one), ★ (new capability they would plausibly adopt), or
    🔒 (security fix). One or two concrete sentences each.
  - \`## Routine\` - one line: "N other bumps (patch releases and transitive
    libraries)."
  - \`## Sources\` - the release-note URLs you actually read.
- If release notes for something interesting cannot be found, say so in one
  line; never guess at changelog contents.
- Output the digest only: no preamble, no sign-off.
EOF
)"

echo "Generating update digest via $backend (this reads release notes; takes a minute or two)..."
if [[ "$backend" == codex ]]; then
  # -o captures just the final message; stdout carries progress events.
  last_msg="$(mktemp -t tgall-digest)"
  trap 'rm -f "$last_msg"' EXIT
  # </dev/null: codex slurps stdin when it is not a TTY (tgall pipes here).
  # --skip-git-repo-check: tgall runs from any cwd; the sandbox is read-only.
  codex exec -s read-only -m gpt-5.5 -c model_reasoning_effort=high \
    --skip-git-repo-check --color never -o "$last_msg" "$prompt" \
    </dev/null >/dev/null 2>&1 ||
    { echo 'Digest generation failed; version diff above still stands.'; exit 0; }
  digest="$(cat "$last_msg")"
else
  digest="$(claude -p "$prompt" \
    --allowedTools 'WebFetch,WebSearch,Bash(gh release:*),Bash(gh api:*),Bash(brew info:*)' \
    2>/dev/null)" ||
    { echo 'Digest generation failed; version diff above still stands.'; exit 0; }
fi
[[ -n "$digest" ]] || { echo 'Digest came back empty; version diff above still stands.'; exit 0; }

mkdir -p "$state/digests"
out="$state/digests/$(date +%Y-%m-%d-%H%M).md"
printf '%s\n' "$digest" | tee "$out"
printf '\nSaved: %s\n' "$out"

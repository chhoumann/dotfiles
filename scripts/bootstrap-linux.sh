#!/usr/bin/env bash
# Bootstrap a Debian/Ubuntu agent box (e.g. agents-fsn1) from this repo.
#
# Idempotent: every step checks before it acts, so rerunning is the normal
# way to converge a box after the repo changes. Run it via
# scripts/sync-remote.sh from the Mac, or directly on the box:
#
#   ~/dotfiles/scripts/bootstrap-linux.sh --git-name "Name" --git-email you@example.com
#
# No Homebrew on Linux: apt where the archive is good enough, upstream
# release binaries in ~/.local/bin where it is not. Secrets are never
# installed here; agent CLIs (claude, codex) need a one-time interactive
# login afterwards.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_BIN="$HOME/.local/bin"

git_name=""
git_email=""

while (($#)); do
  case "$1" in
    --git-name)
      shift
      git_name="${1:-}"
      ;;
    --git-email)
      shift
      git_email="${1:-}"
      ;;
    -h|--help)
      sed -n '2,13p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      printf 'unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
  shift
done

if [[ ! -f /etc/debian_version ]]; then
  echo "This bootstrap targets Debian/Ubuntu; unsupported system." >&2
  exit 1
fi

step() { printf '\n==> %s\n' "$1"; }

mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

step "apt packages"
# gh from GitHub's own apt repo; the Ubuntu archive lags far behind.
if [[ ! -f /etc/apt/sources.list.d/github-cli.list ]]; then
  sudo install -dm 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
    sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
    sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
fi
sudo apt-get update -qq

# Filter the wishlist against what this release actually ships, so one
# missing package (e.g. eza on older Ubuntus) doesn't sink the whole run.
apt_wanted=(
  zsh tmux git curl unzip jq ripgrep fd-find bat tree
  zoxide eza btop direnv shellcheck hyperfine gh
)
apt_missing=()
apt_install=()
for pkg in "${apt_wanted[@]}"; do
  if apt-cache show "$pkg" >/dev/null 2>&1; then
    apt_install+=("$pkg")
  else
    apt_missing+=("$pkg")
  fi
done
sudo apt-get install -y -qq "${apt_install[@]}"
if ((${#apt_missing[@]})); then
  printf 'not in apt on this release, skipped: %s\n' "${apt_missing[*]}"
fi

step "ubuntu binary-name shims (fd, bat)"
if command -v fdfind >/dev/null && [[ ! -e "$LOCAL_BIN/fd" ]]; then
  ln -s "$(command -v fdfind)" "$LOCAL_BIN/fd"
fi
if command -v batcat >/dev/null && [[ ! -e "$LOCAL_BIN/bat" ]]; then
  ln -s "$(command -v batcat)" "$LOCAL_BIN/bat"
fi

step "upstream release binaries"
# install_release <cmd> <owner/repo> <asset-substring>
# Downloads the latest release asset matching the substring, extracts it,
# and installs the binary named <cmd> into ~/.local/bin. Skips when the
# command already exists anywhere on PATH.
install_release() {
  local cmd="$1" repo="$2" match="$3" url tmp
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd already installed"
    return 0
  fi
  url="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" |
    jq -r --arg m "$match" '.assets[].browser_download_url | select(contains($m))' | head -1)"
  if [[ -z "$url" ]]; then
    echo "WARN: no release asset matching '$match' for $repo; skipping $cmd" >&2
    return 0
  fi
  tmp="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp/asset"
  tar -xzf "$tmp/asset" -C "$tmp"
  find "$tmp" -type f -name "$cmd" -exec install -m 755 {} "$LOCAL_BIN/$cmd" \;
  rm -rf "$tmp"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "installed $cmd"
  else
    echo "WARN: $cmd install failed" >&2
  fi
}

# fzf from upstream: the archive's version predates `fzf --zsh`, which the
# zshrc relies on outside of Homebrew.
install_release fzf junegunn/fzf "linux_amd64.tar.gz"
install_release delta dandavison/delta "x86_64-unknown-linux-gnu.tar.gz"
install_release lazygit jesseduffield/lazygit "Linux_x86_64.tar.gz"
install_release zellij zellij-org/zellij "x86_64-unknown-linux-musl.tar.gz"
install_release atuin atuinsh/atuin "x86_64-unknown-linux-gnu.tar.gz"

step "starship"
if command -v starship >/dev/null 2>&1; then
  echo "starship already installed"
else
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN"
fi

step "uv"
if command -v uv >/dev/null 2>&1; then
  echo "uv already installed"
else
  # The installer respects this and leaves shell rc files alone (PATH
  # already covers ~/.local/bin via zshenv).
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 INSTALLER_NO_MODIFY_PATH=1 sh
fi

step "node + agent CLIs"
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y -qq nodejs
fi
command -v pnpm >/dev/null 2>&1 || corepack enable --install-directory "$LOCAL_BIN" pnpm
command -v claude >/dev/null 2>&1 || sudo npm install -g @anthropic-ai/claude-code
command -v codex >/dev/null 2>&1 || sudo npm install -g @openai/codex

step "zinit"
"$DOTFILES_DIR/scripts/bootstrap/install-zinit.sh"

step "git identity"
git_args=(--non-interactive)
[[ -n "$git_name" ]] && git_args+=(--name "$git_name")
[[ -n "$git_email" ]] && git_args+=(--email "$git_email")
"$DOTFILES_DIR/scripts/bootstrap/configure-git.sh" "${git_args[@]}"

step "link dotfiles (dotbot, default profile)"
"$DOTFILES_DIR/install"

step "claude settings"
# The repo file is a baseline, not the live file: Claude Code and the Orca
# hook installer both write to ~/.claude/settings.json (hooks, approved
# permissions), so we merge - baseline wins for the keys it defines,
# machine-generated keys like `hooks` survive.
mkdir -p "$HOME/.claude"
claude_settings="$HOME/.claude/settings.json"
if [[ -s "$claude_settings" ]]; then
  merged="$(jq -s '.[0] * .[1]' "$claude_settings" "$DOTFILES_DIR/claude/settings.json")"
  printf '%s\n' "$merged" > "$claude_settings"
else
  cp "$DOTFILES_DIR/claude/settings.json" "$claude_settings"
fi
echo "merged claude baseline into $claude_settings"

step "codex config"
mkdir -p "$HOME/.codex"
if [[ -f "$HOME/.codex/config.toml" ]]; then
  echo "\$HOME/.codex/config.toml exists; leaving it alone (codex owns it at runtime)"
else
  cp "$DOTFILES_DIR/codex/config.linux.toml" "$HOME/.codex/config.toml"
  echo "installed codex config baseline"
fi

step "login shell"
zsh_path="$(command -v zsh)"
if [[ "$(getent passwd "$USER" | cut -d: -f7)" == "$zsh_path" ]]; then
  echo "login shell already $zsh_path"
else
  grep -qx "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  sudo chsh -s "$zsh_path" "$USER"
  echo "login shell set to $zsh_path"
fi

printf '\nBootstrap complete. One-time manual steps (interactive OAuth, no stored keys):\n'
printf '  claude        # Claude Code login\n'
printf '  codex login   # Codex login\n'

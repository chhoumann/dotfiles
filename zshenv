# Minimal environment for every zsh invocation, including non-interactive
# scripts and GUI-spawned shells. Keep this file fast and side-effect free:
# no output, plugin managers, completions, prompts, aliases, or shell hooks.

export EDITOR="${EDITOR:-vim}"

if [[ -z "${HOMEBREW_PREFIX-}" ]]; then
  if [[ -d /opt/homebrew ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
  elif [[ -d /usr/local/opt || -x /usr/local/bin/brew ]]; then
    export HOMEBREW_PREFIX="/usr/local"
  fi
fi

export BUN_INSTALL="$HOME/.bun"
export DENO_INSTALL="$HOME/.deno"
export PNPM_HOME="$HOME/.local/share/pnpm"
export VP_HOME="${VP_HOME:-$HOME/.vite-plus}"
export UV_TORCH_BACKEND=auto

typeset -U path PATH

_dotfiles_path_prepend() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  path=("${(@)path:#$dir}")
  path=("$dir" "${path[@]}")
}

_dotfiles_path_append() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  path+=("$dir")
}

# Make common Homebrew locations available to non-login, non-interactive zsh
# processes too. Login shells still get the full `brew shellenv` in zprofile.
if [[ -n "${HOMEBREW_PREFIX-}" ]]; then
  _dotfiles_path_prepend "$HOMEBREW_PREFIX/bin"
  _dotfiles_path_prepend "$HOMEBREW_PREFIX/sbin"
fi
_dotfiles_path_append "/usr/local/bin"

_dotfiles_path_prepend "$HOME/bin"
_dotfiles_path_prepend "$HOME/.local/bin"
_dotfiles_path_prepend "$HOME/go/bin"
_dotfiles_path_prepend "$BUN_INSTALL/bin"
_dotfiles_path_prepend "$HOME/.cargo/bin"
_dotfiles_path_prepend "$DENO_INSTALL/bin"
_dotfiles_path_prepend "$VP_HOME/bin"

_dotfiles_path_append "$HOME/.dotnet"

# Keep personal and Vite+ shims ahead of package-manager bins for every zsh invocation.
_dotfiles_path_prepend "$VP_HOME/bin"
_dotfiles_path_prepend "$HOME/.local/bin"
path=("${(@)path:#$PNPM_HOME}")

unfunction _dotfiles_path_prepend _dotfiles_path_append

DOTFILES_DIR="${${(%):-%N}:A:h}"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

source "${DOTFILES_DIR}/shell/shared.zsh"

if [[ -f "$HOME/.config/secrets/api.env" ]]; then
  source "$HOME/.config/secrets/api.env"
fi

# Local machine-specific login shell overrides.
if [[ -f "$HOME/.zprofile.local" ]]; then
  source "$HOME/.zprofile.local"
fi

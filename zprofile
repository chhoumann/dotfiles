if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if [[ -f "$HOME/.config/secrets/api.env" ]]; then
  source "$HOME/.config/secrets/api.env"
fi

# Local machine-specific login shell overrides.
if [[ -f "$HOME/.zprofile.local" ]]; then
  source "$HOME/.zprofile.local"
fi

# Vite+ bin (https://viteplus.dev)
if [[ -f "$HOME/.vite-plus/env" ]]; then
  . "$HOME/.vite-plus/env"
fi

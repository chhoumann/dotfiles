# Shared shell bootstrap for login and interactive Zsh shells.

if [[ -z "${HOMEBREW_PREFIX-}" ]]; then
  if [[ -d /opt/homebrew ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
  elif [[ -d /usr/local/opt || -x /usr/local/bin/brew ]]; then
    export HOMEBREW_PREFIX="/usr/local"
  fi
fi

if [[ -n "${HOMEBREW_PREFIX-}" ]]; then
  _dotfiles_brew_site_functions="$HOMEBREW_PREFIX/share/zsh/site-functions"
  if [[ -d "$_dotfiles_brew_site_functions" ]] && (( ${fpath[(I)$_dotfiles_brew_site_functions]} == 0 )); then
    fpath=("$_dotfiles_brew_site_functions" $fpath)
  fi
  unset _dotfiles_brew_site_functions
fi

if [[ -z "${DOTFILES_VITE_PLUS_ENV_SOURCED-}" && -f "$HOME/.vite-plus/env" ]]; then
  export DOTFILES_VITE_PLUS_ENV_SOURCED=1
  . "$HOME/.vite-plus/env"
fi

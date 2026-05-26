# Initialize variables
export IS_VSCODE=false
export EDITOR="${EDITOR:-vim}"
DOTFILES_DIR="${${(%):-%N}:A:h}"

# GitHub Dark palette — applied to fzf, man, autosuggestion, and syntax
# highlighting. Plugin-array overrides for autosuggest/highlighting live
# *after* the zinit load block below; the env vars set here are read at
# tool-invocation time and are safe to set early.
export MANPAGER="sh -c 'col -bx | bat --language man --plain'"
export MANROFFOPT="-c"
export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border=rounded
  --prompt='❯ '
  --pointer='▶'
  --marker='✓'
  --info=inline
  --color=fg:#c9d1d9,bg:-1,hl:#bc8cff
  --color=fg+:#f0f6fc,bg+:#161b22,hl+:#d2a8ff
  --color=info:#58a6ff,prompt:#3fb950,pointer:#ff7b72
  --color=marker:#d29922,spinner:#58a6ff,header:#8b949e
  --color=border:#30363d,gutter:-1,separator:#30363d
  --color=preview-bg:-1,preview-fg:#c9d1d9
"

source "${DOTFILES_DIR}/shell/shared.zsh"

# VS Code sets a few env vars; avoid spawning subprocesses here.
if [[ -n "${VSCODE_PID-}" || -n "${VSCODE_IPC_HOOK_CLI-}" || "${TERM_PROGRAM-}" == "vscode" ]]; then
  IS_VSCODE=true
fi

# Auto-launch zellij in Ghostty: attach to the most recent session if any,
# otherwise start a fresh one. Set ZELLIJ_AUTO_ATTACH=true to skip the
# session-picker logic and always attach -c; ZELLIJ_AUTO_EXIT=true to close
# the parent shell when zellij exits.
start_zellij() {
    [[ $- == *i* ]] || return 0
    [[ -t 0 && -t 1 ]] || return 0
    [[ "${TERM_PROGRAM-}" == "ghostty" ]] || return 0
    [[ -z "$ZELLIJ" && -z "$TMUX" ]] || return 0
    command -v zellij >/dev/null 2>&1 || return 0

    # GUI-launched shells can inherit /. Seed new zellij sessions from home.
    [[ "$PWD" == "/" ]] && cd -- "$HOME"

    if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
        zellij attach -c
    else
        local sessions last_session
        sessions=$(timeout 2 zellij list-sessions --no-formatting --short 2>/dev/null || true)
        if [[ -z "$sessions" ]]; then
            zellij
        else
            last_session=$(printf '%s\n' "$sessions" | tail -n 1)
            zellij attach "$last_session" || zellij
        fi
    fi

    [[ "$ZELLIJ_AUTO_EXIT" == "true" ]] && exit
}

start_zellij

# Zinit configuration
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ -r "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"
fi

# zsh-completions must load before compinit; zinit cdreplay + snippets after.
if (( ${+functions[zinit]} )); then
  zinit light zsh-users/zsh-completions
fi

# Load completions (must be before syntax-highlighting)
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"
ZSH_COMPDUMP="${ZSH_CACHE_DIR}/zcompdump-${ZSH_VERSION}"
autoload -Uz compinit
typeset -a _zcompdump_refresh
_zcompdump_refresh=("$ZSH_COMPDUMP"(Nmh+24))
if [[ ! -s "$ZSH_COMPDUMP" || ${#_zcompdump_refresh[@]} -gt 0 ]]; then
    compinit -d "$ZSH_COMPDUMP"
else
    compinit -C -d "$ZSH_COMPDUMP"
fi
unset _zcompdump_refresh

if (( ${+functions[zinit]} )); then
  zinit cdreplay -q
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
  zinit snippet OMZP::aws
  zinit snippet OMZP::kubectl
  zinit snippet OMZP::kubectx
  zinit snippet OMZP::command-not-found
fi

## -- Keybinds ---
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
# moving between words with CTRL+left and CTRL+right
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
# undo redo with alt+u and alt+r
bindkey '^[u' undo
bindkey '^[r' redo


## -- History --
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# -- Completion styling --
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
if command -v eza >/dev/null 2>&1; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons --git --group-directories-first "$realpath"'
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always --icons --git --group-directories-first "$realpath"'
else
    # macOS BSD ls: use -G for color when available.
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -G "$realpath"'
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls -G "$realpath"'
fi


# --- Aliases ---
alias lg=lazygit
[[ -x "$HOME/.fly/bin/flyctl" ]] && alias fly="$HOME/.fly/bin/flyctl"

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --git --group-directories-first'
    alias l='eza -al --icons --git --group-directories-first'
    alias ll='eza -al --icons --git --group-directories-first --header'
    alias lt='eza --tree --icons --git --git-ignore --level=2'
    alias llt='eza --tree --icons --git --git-ignore --level=4'
    alias lr='eza -al --icons --git --group-directories-first --sort=modified'
else
    alias l='ls -alh'
    alias ll='ls -alh'
    alias lr='ls -ltrh'
fi

if command -v fd >/dev/null 2>&1; then
    alias find="fd"
fi

alias e="open"
alias c="code"
alias ci="code-insiders"
alias ccc="pbcopy"
alias gdash="gh extension exec dash"
[[ -x "$(command -v topgrade 2>/dev/null)" ]] && alias tgall='topgrade -cy --no-retry'
command -v bat >/dev/null 2>&1 && alias cat="bat"
command -v tofu >/dev/null 2>&1 && alias terraform="tofu"
alias pcl="gh pr list | fzf --preview 'gh pr view {1}' | awk '{ print \$1 }' | xargs gh pr checkout"

source "${DOTFILES_DIR}/shell/lumen.zsh"
source "${DOTFILES_DIR}/shell/git-fzf.zsh"

cdt() {
  local base="${TMPDIR:-/tmp}"
  local raw_label="${1:-${PWD:t}}"
  local label="${raw_label//[^A-Za-z0-9._-]/-}"
  local dir

  [[ -z "$label" ]] && label="tmp"
  dir=$(mktemp -d "${base%/}/${label}.XXXXXXXX") || return 1
  cd "$dir" || return 1
  pwd
}

fp() {
  local root="${1:-.}"
  if command -v fd >/dev/null 2>&1; then
    fd --type f --hidden --no-ignore-vcs --exclude .git --print0 . "$root"
  else
    find "$root" -name .git -prune -o -type f -print0
  fi | fzf --read0 --print0 --multi --preview 'bat --color=always -- {} 2>/dev/null || command cat -- {}' | xargs -0 -I{} realpath -- "{}"
}

# zellij
alias zj="zellij"
alias zja="zellij attach"
alias zjl="zellij list-sessions"

# Track each zellij pane's cwd so floating-pane launchers (yazi, etc.) can land
# in the focused pane's directory. zellij's `Run` doesn't expose focused-pane
# cwd via CLI on macOS, so we tail it from chpwd.
if [[ -n "$ZELLIJ_PANE_ID" ]]; then
  _zellij_cwd_track() {
    print -r -- "$PWD" >| "${TMPDIR:-/tmp}/zellij-cwd-${ZELLIJ_PANE_ID}"
  }
  typeset -ag chpwd_functions
  chpwd_functions+=(_zellij_cwd_track)
  _zellij_cwd_track
fi

ccv() {
  if [[ "$1" == "update" ]]; then
    claude update
  else
    claude --dangerously-skip-permissions "$@"
  fi
}

cx() {
  if [[ "$1" == "update" ]]; then
    bun update -g @openai/codex --latest
  else
    codex --yolo "$@"
  fi
}

function ampx() {
  amp --dangerously-allow-all "${@:1}"
}

# https://github.com/antonmedv/walk
function cdl() {
	cd "$(walk --icons "$@")"
}

# https://github.com/sxyazi/yazi
function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Prompt
if command -v starship >/dev/null 2>&1 && [[ -t 1 ]] && [[ "${TERM-}" != "dumb" ]]; then
  eval "$(starship init zsh)"
fi

# Vim-mode cursor shape: steady block in normal mode, blinking beam in insert.
# zle-keymap-select fires on mode switch; zle-line-init resets the cursor at
# each new prompt; zshexit restores the terminal default on shell exit so we
# don't leave a beam behind. Uses add-zle-hook-widget so we coexist with
# starship's own zle hooks instead of clobbering them.
if [[ -o interactive ]]; then
  autoload -Uz add-zle-hook-widget add-zsh-hook

  _cursor_keymap_select() {
    case "${KEYMAP}" in
      vicmd)      print -n '\e[2 q' ;;  # steady block
      viins|main) print -n '\e[5 q' ;;  # blinking beam
    esac
  }
  add-zle-hook-widget zle-keymap-select _cursor_keymap_select

  _cursor_line_init() { print -n '\e[5 q'; }
  add-zle-hook-widget zle-line-init _cursor_line_init

  _cursor_exit() { print -n '\e[0 q'; }
  add-zsh-hook zshexit _cursor_exit
fi

# PATH management (dedupe + only add existing dirs)
typeset -U path PATH

path_prepend() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  path=("$dir" $path)
}

path_append() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  path+=("$dir")
}

path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/go/bin"

# Optional local CLIs (installed per-machine); only enabled if present.
path_prepend "$HOME/.codeium/windsurf/bin"
path_prepend "$HOME/.antigravity/antigravity/bin"

# Make Intel Homebrew / manual installs usable on Apple Silicon and vice versa.
path_append "/usr/local/bin"

# bun
export BUN_INSTALL="$HOME/.bun"
path_prepend "$BUN_INSTALL/bin"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# cargo
path_prepend "$HOME/.cargo/bin"

# deno
export DENO_INSTALL="$HOME/.deno"
path_prepend "$DENO_INSTALL/bin"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
path_prepend "$PNPM_HOME"

# .NET user tools
path_append "$HOME/.dotnet"

if [[ -n "${HOMEBREW_PREFIX-}" ]]; then
  path_prepend "$HOMEBREW_PREFIX/opt/llvm/bin"
  path_prepend "$HOMEBREW_PREFIX/opt/dotnet@8/bin"

  # Prefer the newest installed OpenJDK.
  for jdk in openjdk@21 openjdk@17 openjdk@11 openjdk; do
    if [[ -d "$HOMEBREW_PREFIX/opt/$jdk/bin" ]]; then
      path_prepend "$HOMEBREW_PREFIX/opt/$jdk/bin"
      break
    fi
  done
fi

export UV_TORCH_BACKEND=auto

## -- Shell Integrations --
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

if command -v fzf >/dev/null 2>&1 && [[ -t 0 ]] && [[ -t 1 ]]; then
    # Faster than `source <(fzf --zsh)` and avoids spawning a process on startup.
    if [[ -r /opt/homebrew/opt/fzf/shell/completion.zsh ]]; then
        source /opt/homebrew/opt/fzf/shell/completion.zsh
        source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
    elif [[ -r /usr/local/opt/fzf/shell/completion.zsh ]]; then
        source /usr/local/opt/fzf/shell/completion.zsh
        source /usr/local/opt/fzf/shell/key-bindings.zsh
    else
        source <(fzf --zsh)
    fi
fi

# fzf-tab should load after `compinit` and after fzf's own shell scripts so it
# becomes the final owner of `Tab`. Autosuggestions should come after that
# because it wraps widgets.
if (( ${+functions[zinit]} )); then
    zinit light Aloxaf/fzf-tab
    zinit light zsh-users/zsh-autosuggestions
    zinit light zsh-users/zsh-syntax-highlighting
fi

# GitHub Dark palette for inline ghost-text and as-you-type highlighting.
# Must come after the plugins load so we override their defaults.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6e7681'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#c9d1d9'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ff7b72,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#ffa657'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#39c5cf,bold'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#39c5cf'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#39c5cf'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#58a6ff'
ZSH_HIGHLIGHT_STYLES[function]='fg=#58a6ff'
ZSH_HIGHLIGHT_STYLES[command]='fg=#58a6ff,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#bc8cff'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#8b949e'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#58a6ff'
ZSH_HIGHLIGHT_STYLES[path]='fg=#c9d1d9,underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#6e7681'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#c9d1d9,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#d29922'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#bc8cff'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#39c5cf'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#39c5cf'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#bc8cff'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#3fb950'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#3fb950'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#3fb950'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#d2a8ff'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#d2a8ff'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#d2a8ff'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#d29922'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#d29922,bold'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#8b949e,italic'
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#39c5cf'
ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#39c5cf'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#58a6ff,bold'
ZSH_HIGHLIGHT_STYLES[bracket-error]='fg=#ff7b72,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=#58a6ff'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=#bc8cff'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=#3fb950'
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=#d29922'
ZSH_HIGHLIGHT_STYLES[bracket-level-5]='fg=#39c5cf'
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='standout'

if command -v atuin >/dev/null 2>&1 && [[ -t 0 ]] && [[ -t 1 ]]; then
  eval "$(atuin init zsh)"      # ctrl+r: history (overrides fzf's)
fi
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"    # per-directory env vars

if [[ -f "$HOME/.config/secrets/api.env" ]]; then
    source "$HOME/.config/secrets/api.env"
elif [[ -f "$HOME/.api_keys" ]]; then
    source "$HOME/.api_keys"
fi

# Local machine-specific overrides (kept out of this repo).
if [[ -f "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi

# Keep personal shims ahead of tool-managed bins so wrappers in ~/.local/bin
# override package launchers when needed.
path=("$HOME/.local/bin" ${path:#$HOME/.local/bin})

# CF CLI completions
[[ -f "$HOME/.config/cf/completions/_cf.zsh" ]] && source "$HOME/.config/cf/completions/_cf.zsh"

command -v but >/dev/null 2>&1 && eval "$(but completions zsh)"
source /Users/christian/.safe-chain/scripts/init-posix.sh # Safe-chain Zsh initialization script

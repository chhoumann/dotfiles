# Initialize variables
export IS_VSCODE=false
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

# Zinit-managed plugin paths. Fast path sources already-installed plugin files
# directly; zinit stays available as the fallback loader when a cache is missing.
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
ZINIT_BASE="${ZINIT_HOME:h}"

_dotfiles_load_zinit() {
  (( ${+functions[zinit]} )) && return 0
  [[ -r "${ZINIT_HOME}/zinit.zsh" ]] || return 1
  source "${ZINIT_HOME}/zinit.zsh"
}

_dotfiles_source_or_zinit_plugin() {
  local plugin_dir="${ZINIT_BASE}/plugins/$1"
  local repo="$2"
  local file="$3"

  if [[ -r "$plugin_dir/$file" ]]; then
    source "$plugin_dir/$file"
  else
    _dotfiles_load_zinit && zinit light "$repo"
  fi
}

_dotfiles_source_or_zinit_snippet() {
  local name="$1"
  local snippet_path="${ZINIT_BASE}/snippets/OMZP::${name}/OMZP::${name}"

  if [[ -r "$snippet_path" ]]; then
    if [[ "$name" == "git" && -n "${commands[git]-}" ]]; then
      local cache="${ZSH_CACHE_DIR}/omzp-git.zsh"
      local cache_header=""
      local expected_header=": dotfiles-cache-command: ${commands[git]} $snippet_path"

      [[ -r "$cache" ]] && IFS= read -r cache_header < "$cache"
      if [[ ! -s "$cache" || "$cache_header" != "$expected_header" || "${commands[git]}" -nt "$cache" || "$snippet_path" -nt "$cache" ]]; then
        local git_version="${${(As: :)$("${commands[git]}" version 2>/dev/null)}[3]}"
        if [[ -n "$git_version" ]]; then
          {
            print -r -- "$expected_header"
            local line
            while IFS= read -r line; do
              if [[ "$line" == git_version=* ]]; then
                print -r -- "git_version='$git_version'"
              else
                print -r -- "$line"
              fi
            done < "$snippet_path"
          } >| "${cache}.tmp" 2>/dev/null && mv "${cache}.tmp" "$cache" || rm -f "${cache}.tmp"
        fi
      fi

      if [[ -s "$cache" ]]; then
        source "$cache"
      else
        source "$snippet_path"
      fi
    else
      source "$snippet_path"
    fi
  else
    _dotfiles_load_zinit && zinit snippet "OMZP::${name}"
  fi
}

# zsh-completions must be in fpath before compinit.
if [[ -d "${ZINIT_BASE}/plugins/zsh-users---zsh-completions/src" ]]; then
  fpath=("${ZINIT_BASE}/plugins/zsh-users---zsh-completions/src" $fpath)
else
  _dotfiles_load_zinit && zinit light zsh-users/zsh-completions
fi

# Load completions (must be before syntax-highlighting)
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
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
fi
_dotfiles_source_or_zinit_snippet git
_dotfiles_source_or_zinit_snippet sudo
_dotfiles_source_or_zinit_snippet aws
_dotfiles_source_or_zinit_snippet kubectl
_dotfiles_source_or_zinit_snippet kubectx
# Disabled because Homebrew's command-not-found handler can make typos feel
# like they hang while it searches for a formula that provides the command.
# Use `brew search <name>` manually when you want install suggestions.
# _dotfiles_source_or_zinit_snippet command-not-found

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
# Update everything (behavior configured in config/topgrade/topgrade.toml),
# then print an AI digest of the version bumps that matter on this machine
# (scripts/update-digest.sh). macOS system updates are excluded; run those
# deliberately via `tgos`.
if command -v topgrade >/dev/null 2>&1; then
  tgall() {
    local state="${TGALL_STATE:-$HOME/.local/state/tgall}" rc
    mkdir -p "$state"
    "${DOTFILES_DIR}/scripts/pkg-manifest.sh" > "$state/manifest.before"
    topgrade "$@"
    rc=$?
    "${DOTFILES_DIR}/scripts/pkg-manifest.sh" > "$state/manifest.after"
    "${DOTFILES_DIR}/scripts/update-digest.sh" "$state/manifest.before" "$state/manifest.after"
    return $rc
  }
fi
alias tgos='sudo softwareupdate --install --all'
alias brewdrift="${DOTFILES_DIR}/scripts/brew-drift.sh"
command -v bat >/dev/null 2>&1 && alias cat="bat"
command -v tofu >/dev/null 2>&1 && alias terraform="tofu"
alias pcl="gh pr list | fzf --preview 'gh pr view {1}' | awk '{ print \$1 }' | xargs gh pr checkout"

source "${DOTFILES_DIR}/shell/lumen.zsh"
source "${DOTFILES_DIR}/shell/git-fzf.zsh"
source "${DOTFILES_DIR}/shell/ssh-fzf.zsh"

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

ccz() {
  local file
  file=$(mktemp "${TMPDIR:-/tmp}/zellij-scrollback.XXXXXX.txt") || return 1

  zellij action dump-screen --full --path "$file" || return 1
  zed "$file" >/dev/null 2>&1 &
  disown $! 2>/dev/null || true
  print -r -- "$file"
}

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

# No permission/sandbox flags on purpose: the safe modes live in the user
# configs (claude defaultMode=auto; codex on-request + workspace-write).
alias ccv=claude
alias cx=codex

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

_dotfiles_source_cached_hook() {
  local cache="$1"
  shift

  local cmd="$1"
  local cmd_path="${commands[$cmd]-}"
  local cache_header=""
  local expected_header

  [[ -n "$cmd_path" ]] || return 1
  expected_header=": dotfiles-cache-command: $cmd_path $*"

  [[ -r "$cache" ]] && IFS= read -r cache_header < "$cache"
  if [[ ! -s "$cache" || "$cache_header" != "$expected_header" || "$cmd_path" -nt "$cache" ]]; then
    {
      print -r -- "$expected_header"
      "$cmd_path" "${@:2}"
    } >| "${cache}.tmp" 2>/dev/null && mv "${cache}.tmp" "$cache" || {
      rm -f "${cache}.tmp"
      return 1
    }
  fi

  source "$cache"
}

# Prompt
if [[ -n "${commands[starship]-}" && -t 1 && "${TERM-}" != "dumb" ]]; then
  _dotfiles_source_cached_hook "${ZSH_CACHE_DIR}/starship-init.zsh" starship init zsh
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

# Interactive PATH additions (dedupe + only add existing dirs). Baseline
# exported PATH and tool-home variables live in zshenv so scripts and
# GUI-spawned shells get them too.
typeset -U path PATH

path_prepend() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  path=("${(@)path:#$dir}")
  path=("$dir" "${path[@]}")
}

# Reassert user tool precedence after login-shell setup such as `brew shellenv`.
# The corresponding exported variables and baseline PATH live in zshenv.
path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/go/bin"
path_prepend "$BUN_INSTALL/bin"
path_prepend "$HOME/.cargo/bin"
path_prepend "$DENO_INSTALL/bin"

# Optional local CLIs (installed per-machine); only enabled if present.
path_prepend "$HOME/.codeium/windsurf/bin"
path_prepend "$HOME/.antigravity/antigravity/bin"

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

path_prepend "${VP_HOME:-$HOME/.vite-plus}/bin"
path=("${(@)path:#$PNPM_HOME}")

[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

[[ -d "$HOME/.safe-chain/bin" ]] && path+=("$HOME/.safe-chain/bin")

_safe_chain_print_warning() {
  printf "\033[43;30mWarning:\033[0m safe-chain is not available to protect you from installing malware. %s will run without it.\n" "$1"
  printf "Install safe-chain by using \033[36mnpm install -g @aikidosec/safe-chain\033[0m.\n"
}

_safe_chain_wrap() {
  local original_cmd="$1"

  if ! whence -p "$original_cmd" >/dev/null 2>&1; then
    command "$@"
    return $?
  fi

  if (( ${+commands[safe-chain]} )); then
    safe-chain "$@"
  else
    _safe_chain_print_warning "$original_cmd"
    command "$@"
  fi
}

npx() { _safe_chain_wrap npx "$@"; }
yarn() { _safe_chain_wrap yarn "$@"; }
pnpm() { _safe_chain_wrap pnpm "$@"; }
pnpx() { _safe_chain_wrap pnpx "$@"; }
rush() { _safe_chain_wrap rush "$@"; }
rushx() { _safe_chain_wrap rushx "$@"; }
bun() { _safe_chain_wrap bun "$@"; }
bunx() { _safe_chain_wrap bunx "$@"; }
pip() { _safe_chain_wrap pip "$@"; }
pip3() { _safe_chain_wrap pip3 "$@"; }
uv() { _safe_chain_wrap uv "$@"; }
uvx() { _safe_chain_wrap uvx "$@"; }
poetry() { _safe_chain_wrap poetry "$@"; }
python() { _safe_chain_wrap python "$@"; }
python3() { _safe_chain_wrap python3 "$@"; }
pipx() { _safe_chain_wrap pipx "$@"; }
npm() {
  if [[ "$1" == "-v" || "$1" == "--version" ]] && [[ $# -eq 1 ]]; then
    command npm "$@"
    return
  fi

  _safe_chain_wrap npm "$@"
}

## -- Shell Integrations --
_dotfiles_source_cached_hook "${ZSH_CACHE_DIR}/zoxide-init.zsh" zoxide init zsh

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
_dotfiles_source_or_zinit_plugin "Aloxaf---fzf-tab" "Aloxaf/fzf-tab" "fzf-tab.zsh"
_dotfiles_source_or_zinit_plugin "zsh-users---zsh-autosuggestions" "zsh-users/zsh-autosuggestions" "zsh-autosuggestions.zsh"
_dotfiles_source_or_zinit_plugin "zsh-users---zsh-syntax-highlighting" "zsh-users/zsh-syntax-highlighting" "zsh-syntax-highlighting.zsh"

if (( ! ${+functions[zinit]} )) && [[ -r "${ZINIT_HOME}/zinit.zsh" ]]; then
  zinit() {
    unfunction zinit
    source "${ZINIT_HOME}/zinit.zsh"
    zinit "$@"
  }
fi
unfunction _dotfiles_load_zinit _dotfiles_source_or_zinit_plugin _dotfiles_source_or_zinit_snippet 2>/dev/null

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

if [[ -n "${commands[atuin]-}" && -t 0 && -t 1 ]]; then
  _dotfiles_source_cached_hook "${ZSH_CACHE_DIR}/atuin-init.zsh" atuin init zsh --disable-ai # ctrl+r: history (overrides fzf's)
fi
_dotfiles_source_cached_hook "${ZSH_CACHE_DIR}/direnv-hook.zsh" direnv hook zsh    # per-directory env vars
unfunction _dotfiles_source_cached_hook 2>/dev/null

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

_dotfiles_load_op_service_account_token() {
  preexec_functions=("${(@)preexec_functions:#_dotfiles_load_op_service_account_token}")
  [[ -n "${OP_SERVICE_ACCOUNT_TOKEN-}" ]] && return 0

  local token
  token=$(security find-generic-password -w -s op-service-account 2>/dev/null) || return 0
  [[ -n "$token" ]] && export OP_SERVICE_ACCOUNT_TOKEN="$token"
}
typeset -ag preexec_functions
preexec_functions=("${(@)preexec_functions:#_dotfiles_load_op_service_account_token}" _dotfiles_load_op_service_account_token)


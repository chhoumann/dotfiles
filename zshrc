# Initialize variables
export IS_VSCODE=false
export EDITOR="${EDITOR:-vim}"
DOTFILES_DIR="${${(%):-%N}:A:h}"

source "${DOTFILES_DIR}/shell/shared.zsh"

# VS Code sets a few env vars; avoid spawning subprocesses here.
if [[ -n "${VSCODE_PID-}" || -n "${VSCODE_IPC_HOOK_CLI-}" || "${TERM_PROGRAM-}" == "vscode" ]]; then
  IS_VSCODE=true
fi

# export ZELLIJ_AUTO_ATTACH=true
# Prefer tmux or zellij without affecting the other; default stays zellij.
export MUX_PREFERRED="${MUX_PREFERRED:-zellij}"
start_preferred_mux() {
    [[ $- == *i* ]] || return 0
    [[ -t 0 && -t 1 ]] || return 0
    [[ "${TERM_PROGRAM-}" == "ghostty" ]] || return 0
    [[ -z "$ZELLIJ" && -z "$TMUX" ]] || return 0

    if [[ "$MUX_PREFERRED" == "tmux" ]] && command -v tmux >/dev/null 2>&1; then
        tmux new -A -s main
    elif command -v zellij >/dev/null 2>&1; then
        if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
            zellij attach -c
        else
            local sessions last_session
            if command -v timeout >/dev/null 2>&1; then
                sessions=$(timeout 2 zellij list-sessions --no-formatting --short 2>/dev/null || true)
            else
                sessions=$(zellij list-sessions --no-formatting --short 2>/dev/null || true)
            fi

            if [[ -z "$sessions" ]]; then
                zellij
            else
                last_session=$(printf '%s\n' "$sessions" | tail -n 1)
                zellij attach "$last_session" || zellij
            fi
        fi

        [[ "$ZELLIJ_AUTO_EXIT" == "true" ]] && exit
    fi
}

start_preferred_mux

# Zinit configuration
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ -r "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"
fi

# Add in Powerlevel10k if desired - remember to comment out starship & use the p10k file
# zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins that extend completions before `compinit`.
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
fi

# Add in snippets
if (( ${+functions[zinit]} )); then
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
  zinit snippet OMZP::aws
  zinit snippet OMZP::kubectl
  zinit snippet OMZP::kubectx
  zinit snippet OMZP::command-not-found
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# https://www.youtube.com/watch?v=ud7YxC33Z3w | "This Zsh config is perhaps my favorite one yet."
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
    alias ls="eza --icons --git"
    alias l='eza -alg --color=always --group-directories-first --git'
    alias ll='eza -aliSgh --color=always --group-directories-first --icons --header --long --git'
    alias lt='eza -@alT --color=always --git'
    alias llt="eza --oneline --tree --icons --git-ignore"
    alias lr='eza -alg --sort=modified --color=always --group-directories-first --git'
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
alias py="python -m pdb -c c"
alias pcl="gh pr list | fzf --preview 'gh pr view {1}' | awk '{ print \$1 }' | xargs gh pr checkout"

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

alias csb="$HOME/projects/claude-manager/claude-squad"

# Git worktree swap functions
gwt-use() {
  local branch="$1"

  # Check if we're in a git repo
  git rev-parse --git-dir &>/dev/null || { echo "Not in a git repository"; return 1; }

  # Get main branch name
  local main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
  main_branch=${main_branch##refs/remotes/origin/}
  [[ -z "$main_branch" ]] && main_branch="main"

  if [[ -z "$branch" ]]; then
    # Build list: branch|path
    local worktrees=()
    local wt_branch wt_path
    while IFS= read -r line; do
      if [[ "$line" == worktree\ * ]]; then
        wt_path="${line#worktree }"
      elif [[ "$line" == branch\ refs/heads/* ]]; then
        wt_branch="${line#branch refs/heads/}"
        worktrees+=("$wt_branch"$'\t'"$wt_path")
      fi
    done < <(git worktree list --porcelain)

    [[ ${#worktrees[@]} -eq 0 ]] && { echo "No worktrees with branches found"; return 1; }

    # If only one worktree, use it directly
    if [[ ${#worktrees[@]} -eq 1 ]]; then
      branch="${worktrees[1]%%$'\t'*}"
      echo "Only one worktree found, using: $branch"
    else
      # Build display list with time and message, sorted by most recent commit
      local unsorted=()
      for entry in "${worktrees[@]}"; do
        local b="${entry%%$'\t'*}"
        local p="${entry#*$'\t'}"
        local timestamp=$(git log -1 --format="%ct" "$b" 2>/dev/null || echo "0")
        local time=$(git log -1 --format="%ar" "$b" 2>/dev/null || echo "unknown")
        local msg=$(git log -1 --format="%s" "$b" 2>/dev/null)
        [[ ${#msg} -gt 40 ]] && msg="${msg:0:40}..."
        unsorted+=("$timestamp"$'\t'"$b"$'\t'"$p"$'\t'"$time"$'\t'"$msg")
      done
      # Sort by timestamp (descending) and remove timestamp column
      local display_list
      display_list=$(printf '%s\n' "${unsorted[@]}" | sort -t$'\t' -k1 -rn | cut -f2-)

      # Preview script with full paths
      local preview_cmd="
        branch=\$(echo {} | cut -f1)
        path=\$(echo {} | cut -f2)
        main=\"origin/$main_branch\"
        printf '\033[1;36m━━━ %s ━━━\033[0m\n\n' \"\$branch\"

        # vs main (from merge-base)
        base=\$(git merge-base \"\$main\" \"\$branch\" 2>/dev/null)
        if [ -n \"\$base\" ]; then
          ahead=\$(git rev-list --count \"\$base\"..\"\$branch\" 2>/dev/null || echo 0)
          behind=\$(git rev-list --count \"\$base\"..\"\$main\" 2>/dev/null || echo 0)
          printf '\033[33m↑%s\033[0m ahead  \033[33m↓%s\033[0m behind %s\n' \"\$ahead\" \"\$behind\" \"\$main\"
        fi

        # vs own remote tracking branch
        tracking=\$(git rev-parse --abbrev-ref \"\$branch\"@{upstream} 2>/dev/null)
        if [ -n \"\$tracking\" ]; then
          push_ahead=\$(git rev-list --count \"\$tracking\"..\"\$branch\" 2>/dev/null || echo 0)
          push_behind=\$(git rev-list --count \"\$branch\"..\"\$tracking\" 2>/dev/null || echo 0)
          if [ \"\$push_ahead\" -gt 0 ] || [ \"\$push_behind\" -gt 0 ]; then
            printf '\033[35m↑%s\033[0m to push  \033[35m↓%s\033[0m to pull\n' \"\$push_ahead\" \"\$push_behind\"
          else
            printf '\033[32m✓ in sync with %s\033[0m\n' \"\$tracking\"
          fi
        else
          printf '\033[2mno remote tracking branch\033[0m\n'
        fi

        printf '\033[2m%s\033[0m\n\n' \"\$path\"
        changes=\$(git diff --shortstat \"\$main\"...\"\$branch\" 2>/dev/null)
        [ -n \"\$changes\" ] && printf '\033[32m%s\033[0m\n\n' \"\$changes\"
        printf '\033[1mRecent commits:\033[0m\n'
        git log --color=always --format='%C(yellow)%h%C(reset) %C(cyan)%ar%C(reset) %s %C(dim)(%an)%C(reset)' -8 \"\$branch\" 2>/dev/null
      "

      local selection=$(echo "$display_list" | fzf \
              --prompt="  " \
              --header="Select a worktree branch to checkout here (ctrl-l: toggle preview)" \
              --preview="$preview_cmd" \
              --preview-window=right:55%:wrap \
              --delimiter=$'\t' \
              --with-nth='1,3,4' \
              --ansi \
              --border=rounded \
              --border-label=" gwt-use " \
              --bind='ctrl-l:toggle-preview')
      [[ -z "$selection" ]] && return 1
      branch="${selection%%$'\t'*}"
    fi
  fi

  # Find the worktree path
  local wt_path=$(git worktree list --porcelain | awk -v b="$branch" '
    /^worktree / { path=$2 }
    /^branch refs\/heads\// { if ($0 ~ b"$") print path }
  ')

  if [[ -z "$wt_path" ]]; then
    echo "No worktree found for branch: $branch"
    return 1
  fi

  printf "\n\033[2m⏸ Detaching worktree at %s...\033[0m\n" "$wt_path"
  git -C "$wt_path" checkout --detach || return 1

  printf "\033[2m⎇ Checking out %s...\033[0m\n" "$branch"
  git checkout "$branch" || return 1

  printf "\n\033[1;32m✓ Now on %s\033[0m\n" "$branch"
}

gwt-return() {
  git rev-parse --git-dir &>/dev/null || { echo "Not in a git repository"; return 1; }

  local branch=$(git branch --show-current)
  if [[ -z "$branch" ]]; then
    echo "Not on a branch (detached HEAD?)"
    return 1
  fi

  # Find detached worktrees
  local detached=$(git worktree list | awk '/detached/ {print $1}')
  [[ -z "$detached" ]] && { echo "No detached worktrees found"; return 1; }

  local count=$(echo "$detached" | wc -l | tr -d ' ')
  local wt_path

  if [[ "$count" -eq 1 ]]; then
    wt_path="$detached"
    echo "Only one detached worktree found, using: $wt_path"
  else
    wt_path=$(echo "$detached" | fzf \
        --prompt="↩ Return '$branch' to: " \
        --header="Detached worktrees" \
        --preview='printf "\033[1;36m━━━ %s ━━━\033[0m\n\n" "$(basename {})"; git -C {} status --short 2>/dev/null; echo; git -C {} log --oneline -5 2>/dev/null' \
        --preview-window=right:50%:wrap \
        --ansi \
        --border=rounded \
        --border-label=" gwt-return ")
    [[ -z "$wt_path" ]] && return 1
  fi

  local main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  [[ -z "$main_branch" ]] && main_branch="main"

  printf "\n\033[2m⎇ Switching to %s...\033[0m\n" "$main_branch"
  git checkout "$main_branch" || { git checkout main 2>/dev/null || git checkout master; } || return 1

  printf "\033[2m↩ Restoring %s in %s...\033[0m\n" "$branch" "$wt_path"
  git -C "$wt_path" checkout "$branch" || return 1

  printf "\n\033[1;32m✓ %s restored to %s\033[0m\n" "$branch" "$(basename "$wt_path")"
}

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
path_prepend "$HOME/.opencode/bin"
path_prepend "$HOME/.codeium/windsurf/bin"
path_prepend "$HOME/.antigravity/antigravity/bin"
path_append "$HOME/Developer/vr/scripts"

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

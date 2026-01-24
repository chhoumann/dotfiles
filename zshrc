# Initialize Variables
export IS_VSCODE=false
export EDITOR="zed"


# Check if running in VSCode
if [[ $(printenv | grep -c "VSCODE_") -gt 0 ]]; then
    export IS_VSCODE=true
fi

# export ZELLIJ_AUTO_ATTACH=true
if [ "$TERM_PROGRAM" = "ghostty" ]; then
    if [[ -z "$ZELLIJ" ]]; then
        if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
            zellij attach -c
        else
		sessions=$(zellij list-sessions --no-formatting --short)

		# Check if there are any sessions
		if [ -z "$sessions" ]; then
		    # No sessions exist; start a new one
		    zellij
		else
		    # Attach to the most recently used session
		    # Assuming the last session in the list is the most recent
		    last_session=$(echo "$sessions" | tail -n 1)
		    zellij attach "$last_session"
		fi
        fi

        if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
            exit
        fi
    fi
fi

# Zinit configuration
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k if desired - remember to comment out starship & use the p10k file
# zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Load completions (must be before syntax-highlighting)
autoload -Uz compinit && compinit
zinit cdreplay -q

# Syntax highlighting should be loaded last
zinit light zsh-users/zsh-syntax-highlighting

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

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
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'


# --- Aliases ---
alias lg=lazygit
alias fly=~/.fly/bin/flyctl

if type eza >/dev/null 2>&1; then
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

if type fd >/dev/null 2>&1; then
    alias find="fd"
fi

alias e="open"
alias c="code"
alias ci="code-insiders"
alias ccc="pbcopy"
alias gdash="gh extension exec dash"
alias cat="bat"
alias py="python -m pdb -c c"
alias pcl="gh pr list | fzf --preview 'gh pr view {1}' | awk '{ print \$1 }' | xargs gh pr checkout"

# zellij
alias zj="zellij"
alias zja="zellij attach"
alias zjl="zellij list-sessions"

alias csb="~/projects/claude-manager/claude-squad"

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
    codex --enable web_search_request --yolo "$@"
  fi
}

function ampx() {
  amp --dangerously-allow-all "${@:1}"
}

# https://github.com/antonmedv/walk
function cdl() {
  cd "$(walk --icons $@)"
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

eval "$(starship init zsh)"

# Set PATH
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/go/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"

# mise (manages node, python, etc. - replaces fnm)
eval "$(mise activate zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# deno
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"



# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export UV_TORCH_BACKEND=auto

## -- Shell Integrations --
eval "$(zoxide init zsh)"
source <(fzf --zsh)           # ctrl+t: file search, alt+c: cd to dir
eval "$(atuin init zsh)"      # ctrl+r: history (overrides fzf's)

# direnv (per-directory env vars)
eval "$(direnv hook zsh)"

export PATH=$PATH:$HOME/.dotnet

if [ -f ~/.config/secrets/api.env ]; then
    source ~/.config/secrets/api.env
elif [ -f ~/.api_keys ]; then
    source ~/.api_keys
fi
export PATH="/opt/homebrew/opt/dotnet@8/bin:$PATH"

# opencode
export PATH=/Users/christian/.opencode/bin:$PATH
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

# Added by Windsurf
export PATH="/Users/christian/.codeium/windsurf/bin:$PATH"
export PATH="$PATH:/Users/christian/Developer/vr/scripts"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# Added by Antigravity
export PATH="/Users/christian/.antigravity/antigravity/bin:$PATH"

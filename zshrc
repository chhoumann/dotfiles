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

ccv() {
  if [[ "$1" == "update" ]]; then
    bun update -g @anthropic-ai/claude-code --latest
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

function update_coding_agents() {
  local -a agents updated failed skipped
  local -A updates
  local name cmd

  agents=(amp gemini claude codex opencode)
  updates=(
    amp     'amp update'
    gemini  'gemini update'
    claude  'bun update -g @anthropic-ai/claude-code --latest'
    codex   'bun update -g @openai/codex --latest'
    opencode 'bun update -g opencode-ai --latest'
  )

  for name in "${agents[@]}"; do
    cmd="${updates[$name]}"
    case "$name" in
      claude|codex|opencode)
        command -v bun >/dev/null 2>&1 || { skipped+=("$name"); continue; }
        ;;
    esac
    command -v "$name" >/dev/null 2>&1 || { skipped+=("$name"); continue; }

    if ${(z)cmd}; then
      updated+=("$name")
    else
      failed+=("$name")
    fi
  done

  (( ${#updated[@]} )) && echo "updated: ${updated[*]}"
  (( ${#skipped[@]} )) && echo "skipped (missing): ${skipped[*]}"
  if (( ${#failed[@]} )); then
    echo "failed: ${failed[*]}"
    return 1
  fi
}

alias uca="update_coding_agents"

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

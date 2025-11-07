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
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# eval "$(fnm env --use-on-cd)" # --use-on-cd automatically runs fnm use when you cd into a directory with a .node-version file
# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found


# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# if not using warp:
if [ "$TERM_PROGRAM" != "WarpTerminal" ]; then
  plugins=(git zsh-z zsh-autosuggestions)
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

alias e="explorer.exe"
alias c="code"
alias ci="code-insiders"
alias cs="cursor"
alias ccc="pbcopy"
alias gdash="gh extension exec dash"
alias foxpdf="/mnt/c/Program\ Files\ \(x86\)/Foxit\ Software/Foxit\ PDF\ Reader/FoxitPDFReader.exe"
alias cat="bat"
alias py="python -m pdb -c c"
alias pcl="gh pr list | fzf --preview 'gh pr view {1}' | awk '{ print \$1 }' | xargs gh pr checkout"
alias p="cd ~/projects"

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
    # Can add -c model_reasoning_effort='high' to enable high reasoning; removed due to
    # gpt-5-codex having dynamic reasoning effort.
    codex -m gpt-5-codex --enable web_search_request --yolo -c model_reasoning_summary_format=experimental "$@"
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

# Run Docker Service: https://nickjanetakis.com/blog/install-docker-in-wsl-2-without-docker-desktop
if grep -q "microsoft" /proc/version > /dev/null 2>&1; then
    if service docker status 2>&1 | grep -q "is not running"; then
        wsl.exe --distribution "${WSL_DISTRO_NAME}" --user root \
            --exec /usr/sbin/service docker start > /dev/null 2>&1
    fi
fi

# Set PATH
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=$HOME/go/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"

eval "$(fnm env --use-on-cd)" # --use-on-cd automatically runs fnm use when you cd into a directory with a .node-version file
eval "$(fnm completions --shell zsh)"

# bun completions
[ -s "~/.bun/_bun" ] && source "~/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# deno
export DENO_INSTALL="~/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# homebrew
# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# :)
export PATH=~/.local/bin:$PATH

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# to fix cudnn for wsl
export LD_LIBRARY_PATH=/usr/lib/wsl/lib:$LD_LIBRARY_PATH
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

PATH="~/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="~/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="~/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"~/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=~/perl5"; export PERL_MM_OPT;

UV_TORCH_BACKEND=auto

eval "$(zoxide init zsh)"

. "$HOME/.cargo/env"

export PATH=$PATH:$HOME/.dotnet

if [ -f ~/.api_keys ]; then
    source ~/.api_keys
fi

## -- Shell Integrations --
source <(fzf --zsh)
export PATH="/opt/homebrew/opt/dotnet@8/bin:$PATH"

# opencode
export PATH=/Users/christian/.opencode/bin:$PATH
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"

# Initialize Variables
export IS_VSCODE=false
export EDITOR="code"


# Check if running in VSCode
if [[ $(printenv | grep -c "VSCODE_") -gt 0 ]]; then
    export IS_VSCODE=true
fi

# Terminal Specific Configurations
if [ "$TERM_PROGRAM" != "WarpTerminal" ] && [ "$IS_VSCODE" = false ]; then
  if [[ -z "$ZELLIJ" ]]; then
      if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
          zellij attach -c
      else
          zellij
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
    alias l='ls -alh --group-directories-first'
    alias ll='ls -al --group-directories-first'
    alias lr='ls -ltrh --group-directories-first'
fi

if type fd >/dev/null 2>&1; then
    alias find="fd"
fi

alias e="explorer.exe"
alias c="cursor"
alias gdash="gh extension exec dash"
alias foxpdf="/mnt/c/Program\ Files\ \(x86\)/Foxit\ Software/Foxit\ PDF\ Reader/FoxitPDFReader.exe"
alias cat="bat"
alias py="python -m pdb -c c"
alias pcl="gh pr list | fzf --preview 'gh pr view {1}' | awk '{ print \$1 }' | xargs gh pr checkout"
alias p="cd ~/projects"

alias claude="~/.claude/local/claude"
alias csb="~/projects/claude-manager/claude-squad"

function ccv() {
  local env_vars=(
    "ENABLE_BACKGROUND_TASKS=true"
    "FORCE_AUTO_BACKGROUND_TASKS=false"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=true"
    "CLAUDE_CODE_ENABLE_UNIFIED_READ_TOOL=true"
    # "CLAUBBIT=true"
  )
  
  local claude_args=()
  
  if [[ "$1" == "-y" ]]; then
    claude_args+=("--dangerously-skip-permissions")
  elif [[ "$1" == "-r" ]]; then
    claude_args+=("--resume")
  elif [[ "$1" == "-ry" ]] || [[ "$1" == "-yr" ]]; then
    claude_args+=("--resume" "--dangerously-skip-permissions")
  fi
  
  env "${env_vars[@]}" claude "${claude_args[@]}"
}


function init-video() {
  local var vid_root="/mnt/d/Content/$1"
  mkdir -p "$vid_root"
  mkdir -p "$vid_root/Audio"
  mkdir -p "$vid_root/Footage"
  mkdir -p "$vid_root/Graphics"
  mkdir -p "$vid_root/Project Files"
  mkdir -p "$vid_root/Drafts"
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
export PATH=/usr/local/zig:$PATH
export ZIG_INSTALL_PREFIX=/usr/local/zig

export HOMEBREW_CURL_PATH=/home/linuxbrew/.linuxbrew/bin/curl

eval "$(fnm env --use-on-cd)" # --use-on-cd automatically runs fnm use when you cd into a directory with a .node-version file
eval "$(fnm completions --shell zsh)"

# bun completions
[ -s "~/.bun/_bun" ] && source "~/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# deno
export DENO_INSTALL="~/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

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

source "$HOME/.rye/env"

if [ -f ~/.api_keys ]; then
    source ~/.api_keys
fi

## -- Shell Integrations --
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"

. "$HOME/.cargo/env"
# opencode
export PATH=/home/christian/.opencode/bin:$PATH

# Had an issue where I couldn't open a terminal on first open due to "open terminal failed: not a terminal"
# https://github.com/romkatv/powerlevel10k/issues/1203
# if [ -z "$TMUX" ]; then
#   exec tmux new-session -A -s workspace
# fi

export IS_VSCODE=false

if [[ $(printenv | grep -c "VSCODE_") -gt 0 ]]; then
    export IS_VSCODE=true
fi

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

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
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

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

export PATH=$HOME/go/bin:$PATH


# Path to your oh-my-zsh installation.
# export ZSH="$HOME/.oh-my-zsh"
export PATH="$PATH:/usr/local/bin/python"
export EDITOR="code"

eval "$(fnm env --use-on-cd)" # --use-on-cd automatically runs fnm use when you cd into a directory with a .node-version file
eval "$(fnm completions --shell zsh)"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# if not using warp:
# if [ "$TERM_PROGRAM" != "WarpTerminal" ]; then
#   plugins=(git zsh-z rye zsh-autosuggestions zsh-completions zsh-syntax-highlighting)
# fi

# fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

# source $ZSH/oh-my-zsh.sh

# Use Rye instead
## export PYENV_ROOT="$HOME/.pyenv"
## command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
## eval "$(pyenv init -)"
## eval "$(pyenv virtualenv-init -)"


# https://www.youtube.com/watch?v=ud7YxC33Z3w | "This Zsh config is perhaps my favorite one yet."
## -- Keybinds ---
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

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
alias c="code"
alias cs="cursor"
alias gdash="gh extension exec dash"
alias foxpdf="/mnt/c/Program\ Files\ \(x86\)/Foxit\ Software/Foxit\ PDF\ Reader/FoxitPDFReader.exe"
alias cat="bat"
alias py="python -m pdb -c c"
alias pcl="gh pr list | fzf --preview 'gh pr view {1}' | awk '{ print \$1 }' | xargs gh pr checkout"

# Code workspaces
alias cm="code ~/masters.code-workspace"

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
export PNPM_HOME="~/.local/share/pnpm"
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

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('~/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "~/anaconda3/etc/profile.d/conda.sh" ]; then
        . "~/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="~/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export MODULAR_HOME="~/.modular"
export PATH="~/.modular/pkg/packages.modular.com_mojo/bin:$PATH"
source "$HOME/.rye/env"

## -- Shell Integrations --
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"
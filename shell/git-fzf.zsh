# Fzf-powered git pickers. Sourced from zshrc.
#
# gfb  — fuzzy switch branch (local + remote tracked); creates a local
#        tracking branch if the selection is a remote
# gfl  — browse git log graph; enter shows the commit, ctrl-y copies SHA
# gfs  — fuzzy pick stash: enter applies, ctrl-p pops, ctrl-d drops
# gfw  — fuzzy switch worktrees; cd into the selected one
#
# The two-letter `gf` prefix is unique (no oh-my-zsh git alias clash) and
# reads as "git fuzzy". All quietly no-op outside a git repo.

_in_git_repo() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }

gfb() {
  _in_git_repo || { echo "not in a git repo" >&2; return 1; }
  local branch
  branch=$(
    git for-each-ref --format='%(refname:short)' refs/heads refs/remotes \
      --sort=-committerdate \
    | sed 's|^origin/||' \
    | awk '!seen[$0]++ && $0 != "HEAD"' \
    | fzf --no-multi --height=40% --reverse \
          --header='Switch branch' \
          --preview='git log --color=always --oneline --decorate -20 {}' \
          --preview-window=right:60%
  ) || return
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git switch "$branch"
  else
    git switch -c "$branch" --track "origin/$branch"
  fi
}

gfl() {
  _in_git_repo || { echo "not in a git repo" >&2; return 1; }
  git log --color=always --oneline --decorate --graph --all \
  | fzf --ansi --no-sort --reverse --tiebreak=index --height=80% \
        --header='Browse commits — enter: show, ctrl-y: copy SHA' \
        --preview='f() { echo "$1" | grep -o "[a-f0-9]\{7,\}" | head -1; }; \
                   sha=$(f {}); [ -n "$sha" ] && git show --color=always "$sha"' \
        --preview-window=right:60% \
        --bind='enter:execute:f() { echo "$1" | grep -o "[a-f0-9]\{7,\}" | head -1; }; sha=$(f {}); [ -n "$sha" ] && git show "$sha" | less -R' \
        --bind='ctrl-y:execute-silent:f() { echo "$1" | grep -o "[a-f0-9]\{7,\}" | head -1; }; f {} | pbcopy'
}

gfs() {
  _in_git_repo || { echo "not in a git repo" >&2; return 1; }
  local stashes selection key entry sha
  stashes=$(git stash list)
  [[ -z "$stashes" ]] && { echo "no stashes"; return 1; }

  selection=$(printf '%s\n' "$stashes" \
    | fzf --ansi --no-multi --reverse --height=50% \
          --header='enter: apply  ctrl-p: pop  ctrl-d: drop' \
          --preview='echo {} | sed -E "s/:.*//" | xargs -I% git stash show -p --color=always %' \
          --preview-window=right:60% \
          --expect=enter,ctrl-d,ctrl-p) || return

  key=$(printf '%s\n' "$selection" | head -1)
  entry=$(printf '%s\n' "$selection" | tail -1)
  sha=$(printf '%s\n' "$entry" | sed -E 's/:.*//')
  [[ -z "$sha" ]] && return 1

  case "$key" in
    enter)   git stash apply "$sha" ;;
    ctrl-d)  git stash drop  "$sha" ;;
    ctrl-p)  git stash pop   "$sha" ;;
  esac
}

gfw() {
  _in_git_repo || { echo "not in a git repo" >&2; return 1; }
  local target
  target=$(git worktree list \
    | fzf --no-multi --no-sort --reverse --height=40% \
          --header='Switch worktree' \
          --preview='echo {} | awk "{print \$1}" \
                     | xargs -I% sh -c "cd % && git log --oneline --decorate --color=always -10"' \
          --preview-window=right:60% \
    | awk '{print $1}') || return
  [[ -d "$target" ]] && cd "$target"
}

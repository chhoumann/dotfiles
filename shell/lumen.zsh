# lumen diff helpers — `ld <subcommand>` dispatcher with rich completions.
#
#   ld          lumen diff (current uncommitted)
#   ld p  [#]   pick / open PR
#   ld pm [#]   pick / open one of your PRs
#   ld c  [sha] pick / open commit
#   ld cs [sha] pick / open commit, stacked → HEAD
#   ld b  [br]  pick / open branch...HEAD
#   ld m        diff vs origin's default branch
#   ld mw       diff vs origin's default branch + working tree
#   ld f  [pa]  pick / open file with --focus
#   ld w        --watch mode
#   ld h        help / status header
#
# Hit TAB after `ld ` for subcommands, or after `ld <sub> ` for targets
# (PR numbers, SHAs, branches, files) — all with descriptions.

command -v lumen >/dev/null 2>&1 || return 0

typeset -g _LUMEN_ALIASES_FILE="${${(%):-%x}:A}"

# ───── dispatcher ─────

ld() {
  if [[ $# -eq 0 ]]; then
    command lumen diff
    return
  fi

  local sub="$1"; shift
  case "$sub" in
    p)        _ld_pr "$@" ;;
    pm)       _ld_pr_mine "$@" ;;
    c)        _ld_commit "$@" ;;
    cs)       _ld_commit_stacked "$@" ;;
    b)        _ld_branch "$@" ;;
    m)        _ld_main "$@" ;;
    mw)       _ld_main_worktree "$@" ;;
    f)        _ld_file "$@" ;;
    w)        command lumen diff --watch "$@" ;;
    h|help)   _ld_help ;;
    *)        command lumen diff "$sub" "$@" ;;  # passthrough (sha, ref, range)
  esac
}

# ───── subcommand implementations ─────

_ld_pr() {
  local pr="${1#\#}"
  if [[ -z "$pr" ]]; then
    pr=$(gh pr list --limit 50 \
          --json number,title,author,headRefName \
          --template '{{range .}}{{printf "#%v\t%s\t%s\t%s\n" .number .title .author.login .headRefName}}{{end}}' \
        | fzf --preview 'gh pr view {1} 2>/dev/null' --preview-window=right:60% \
        | awk '{print $1}' | tr -d '#')
  fi
  [[ -n "$pr" ]] && command lumen diff --pr "$pr"
}

_ld_pr_mine() {
  local pr="${1#\#}"
  if [[ -z "$pr" ]]; then
    pr=$(gh pr list --author '@me' --limit 30 \
          --json number,title,headRefName \
          --template '{{range .}}{{printf "#%v\t%s\t%s\n" .number .title .headRefName}}{{end}}' \
        | fzf --preview 'gh pr view {1} 2>/dev/null' --preview-window=right:60% \
        | awk '{print $1}' | tr -d '#')
  fi
  [[ -n "$pr" ]] && command lumen diff --pr "$pr"
}

_ld_commit() {
  local sha="$1"
  if [[ -z "$sha" ]]; then
    sha=$(git log --all --color=always --pretty=format:'%C(auto)%h %s %C(dim)%an, %ar' -n 500 \
        | fzf --ansi \
              --preview 'git show --color=always --stat --patch {1} | delta' \
              --preview-window=right:60% \
        | awk '{print $1}')
  fi
  [[ -n "$sha" ]] && command lumen diff "$sha"
}

_ld_commit_stacked() {
  local sha="$1"
  if [[ -z "$sha" ]]; then
    sha=$(git log --color=always --pretty=format:'%C(auto)%h %s %C(dim)%an, %ar' -n 200 \
        | fzf --ansi --preview 'git show --color=always --stat {1}' \
        | awk '{print $1}')
  fi
  [[ -n "$sha" ]] && command lumen diff --stacked "${sha}^..HEAD"
}

_ld_branch() {
  local branch="$1"
  if [[ -z "$branch" ]]; then
    branch=$(git for-each-ref --sort=-committerdate \
                --format='%(refname:short)' refs/heads/ \
          | fzf --preview 'git log --oneline --color=always --decorate {1} -n 25')
  fi
  [[ -n "$branch" ]] && command lumen diff "${branch}...HEAD"
}

_ld_main() {
  local base
  base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
  if [[ -z "$base" ]]; then
    if git rev-parse --verify main >/dev/null 2>&1; then
      base=main
    else
      base=master
    fi
  fi
  command lumen diff "${base}...HEAD" "$@"
}

_ld_main_worktree() {
  local base_ref merge_base
  base_ref=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)

  if [[ -z "$base_ref" ]]; then
    if git rev-parse --verify origin/main >/dev/null 2>&1; then
      base_ref=origin/main
    elif git rev-parse --verify origin/master >/dev/null 2>&1; then
      base_ref=origin/master
    elif git rev-parse --verify main >/dev/null 2>&1; then
      base_ref=main
    else
      base_ref=master
    fi
  fi

  merge_base=$(git merge-base "$base_ref" HEAD) || return
  command lumen diff "${merge_base}..-" "$@"
}

_ld_file() {
  local file="$1"
  if [[ -z "$file" ]]; then
    file=$(git diff --name-only HEAD \
        | fzf --preview 'git diff --color=always HEAD -- {}')
  fi
  [[ -n "$file" ]] && command lumen diff --focus "$file"
}

_ld_status() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local branch base staged unstaged untracked ab="" pr_info=""
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  unstaged=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')

  if [[ -n "$base" ]] && git rev-parse --verify "origin/$base" >/dev/null 2>&1; then
    local lr behind ahead
    lr=$(git rev-list --left-right --count "origin/${base}...HEAD" 2>/dev/null)
    behind=${lr%%	*}
    ahead=${lr##*	}
    ab=" ↑${ahead} ↓${behind}"
  fi

  if command -v gh >/dev/null && git remote get-url origin 2>/dev/null | grep -q github; then
    local open mine
    open=$(gh pr list --limit 100 --json number -q 'length' 2>/dev/null)
    mine=$(gh pr list --author "@me" --limit 100 --json number -q 'length' 2>/dev/null)
    [[ -n "$open" ]] && pr_info="  PRs ${open} open / ${mine} yours"
  fi

  print -P "%F{cyan}━━ ${PWD:t} ━━%f  %F{green}${branch}%f → %F{yellow}${base:-(no upstream)}%f${ab}"
  print -P "  ${staged} staged, ${unstaged} unstaged, ${untracked} untracked${pr_info}"
}

_ld_help() {
  _ld_status
  print ""
  print -P "%F{cyan}usage%f: ld [subcommand] [target]   (TAB after \`ld \` shows all)"
  print ""
  print -P "  %F{yellow}ld%f          lumen diff (current uncommitted)"
  print -P "  %F{yellow}ld p%f  [#]   open PR (or pick interactively)"
  print -P "  %F{yellow}ld pm%f [#]   your PRs"
  print -P "  %F{yellow}ld c%f  [sha] commit"
  print -P "  %F{yellow}ld cs%f [sha] commit, stacked → HEAD"
  print -P "  %F{yellow}ld b%f  [br]  branch...HEAD"
  print -P "  %F{yellow}ld m%f        vs origin default branch"
  print -P "  %F{yellow}ld mw%f       vs origin default branch + working tree"
  print -P "  %F{yellow}ld f%f  [pa]  file with --focus"
  print -P "  %F{yellow}ld w%f        --watch mode"
  print -P "  %F{yellow}ld h%f        this help"
}

# ───── zsh completion ─────

_ld_complete_pr() {
  local -a prs
  prs=("${(@f)$(gh pr list --limit 50 \
      --json number,title,author \
      --jq '.[] | "\(.number):\(.author.login) — \(.title)"' 2>/dev/null)}")
  _describe -t prs 'open PR' prs
}

_ld_complete_pr_mine() {
  local -a prs
  prs=("${(@f)$(gh pr list --author '@me' --limit 30 \
      --json number,title,headRefName \
      --jq '.[] | "\(.number):\(.headRefName) — \(.title)"' 2>/dev/null)}")
  _describe -t prs 'your PR' prs
}

_ld_complete_commit() {
  local -a commits
  commits=("${(@f)$(git log --pretty=format:'%h:%s' -n 200 2>/dev/null)}")
  _describe -t commits 'commit' commits
}

_ld_complete_branch() {
  local -a branches
  branches=("${(@f)$(git for-each-ref --sort=-committerdate \
      --format='%(refname:short):%(committerdate:relative) — %(contents:subject)' \
      refs/heads/ 2>/dev/null)}")
  _describe -t branches 'branch' branches
}

_ld_complete_file() {
  local -a files
  files=("${(@f)$(git -c color.status=false status --short 2>/dev/null \
      | awk '{ status=substr($0,1,2); $1=""; sub(/^ /,""); printf "%s:[%s]\n", $0, status }')}")
  _describe -t files 'changed file' files
}

_ld() {
  local context state state_descr line
  typeset -A opt_args

  _arguments -C \
    '1: :->subcmd' \
    '*:: :->args'

  case $state in
    subcmd)
      local -a subs
      subs=(
        'p:open PR (interactive picker if no #)'
        'pm:your PRs'
        'c:commit'
        'cs:commit, stacked → HEAD'
        'b:branch (branch...HEAD)'
        'm:vs origin default branch'
        'mw:vs origin default branch + working tree'
        'f:changed file (--focus)'
        'w:--watch mode'
        'h:help / status'
      )
      _describe -t subcommands 'ld subcommand' subs
      ;;
    args)
      case $line[1] in
        p)    _ld_complete_pr ;;
        pm)   _ld_complete_pr_mine ;;
        c|cs) _ld_complete_commit ;;
        b)    _ld_complete_branch ;;
        f)    _ld_complete_file ;;
      esac
      ;;
  esac
}
compdef _ld ld

# Fzf-powered SSH host picker. Sourced from zshrc.
#
# sf [query] - fuzzy pick a host from ~/.ssh/config (Include directives are
#              followed, wildcard patterns skipped). Preview shows the
#              resolved config from `ssh -G`. Enter connects, ctrl-y copies
#              user@hostname. With a query argument that matches a single
#              host, connects immediately without showing the picker.

# Collect ~/.ssh/config plus everything reachable through Include directives
# (tilde, relative-to-~/.ssh, and glob paths all supported).
_sf_config_files() {
  local -a queue=("$HOME/.ssh/config")
  local -A seen
  local f line p
  local -a words matches
  while (( ${#queue} )); do
    f=${queue[1]}
    shift queue
    [[ -r $f && -z ${seen[$f]} ]] || continue
    seen[$f]=1
    print -r -- "$f"
    while IFS= read -r line; do
      words=(${(z)line})
      [[ ${(L)words[1]} == include ]] || continue
      for p in "${(@)words[2,-1]}"; do
        p=${p/#\~/$HOME}
        [[ $p == /* ]] || p="$HOME/.ssh/$p"
        matches=(${~p}(N))
        queue+=($matches)
      done
    done <"$f"
  done
}

sf() {
  local -a files hosts
  files=(${(f)"$(_sf_config_files)"})
  hosts=(${(f)"$(
    awk 'tolower($1) == "host" {
           for (i = 2; i <= NF; i++) if ($i !~ /[*?!]/) print $i
         }' $files 2>/dev/null | sort -u
  )"})
  (( ${#hosts} )) || { echo "no hosts configured in ~/.ssh/config" >&2; return 1 }

  local selection key host
  selection=$(
    printf '%s\n' $hosts \
    | fzf --no-multi --height=50% --reverse \
          --query="$*" --select-1 \
          --header='SSH - enter: connect, ctrl-y: copy user@host' \
          --preview='ssh -G {} 2>/dev/null \
                     | grep --color=always -iE "^(hostname|user|port|identityfile|identityagent|proxycommand|proxyjump|forwardagent|requesttty|remotecommand) "' \
          --preview-window=right:55% \
          --expect=ctrl-y
  ) || return
  key=${selection%%$'\n'*}
  host=${selection##*$'\n'}
  [[ -n $host ]] || return

  if [[ $key == ctrl-y ]]; then
    local target
    target=$(ssh -G "$host" 2>/dev/null \
             | awk '/^user /{u=$2} /^hostname /{h=$2} END{print u "@" h}')
    print -rn -- "$target" | pbcopy
    echo "copied $target"
  else
    ssh "$host"
  fi
}

#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="${DOTFILES_DIR}/scripts/bootstrap"

yes_mode=false
non_interactive=false
dry_run=false
with_app_state=false

defaults_mode="ask"
touchid_mode="ask"
git_mode="ask"
shell_mode="yes"

git_name=""
git_email=""

steps=(xcode brew packages zinit vite directories link defaults touchid git shell)

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [options]

Options:
  --yes                 Accept safe defaults for optional steps
  --non-interactive     Never prompt; skip optional steps unless explicitly enabled
  --dry-run             Print the steps/commands that would run
  --with-app-state      Also link the optional apps profile
  --defaults            Apply macOS defaults without prompting
  --skip-defaults       Skip macOS defaults
  --touchid             Enable Touch ID for sudo without prompting
  --skip-touchid        Skip Touch ID setup
  --skip-git            Skip git configuration
  --skip-shell          Skip setting the default shell
  --git-name NAME       Set git user.name noninteractively
  --git-email EMAIL     Set git user.email noninteractively
  --only STEPS          Comma-separated step list
  -h, --help            Show this help

Examples:
  ./bootstrap.sh
  ./bootstrap.sh --yes --with-app-state
  ./bootstrap.sh --non-interactive --git-name "Your Name" --git-email "you@example.com"
  ./bootstrap.sh --only brew,packages,vite,link
EOF
}

join_by() {
  local sep="$1"
  shift
  local first=true
  for item in "$@"; do
    if $first; then
      printf '%s' "$item"
      first=false
    else
      printf '%s%s' "$sep" "$item"
    fi
  done
}

contains_step() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

run_step() {
  local step_name="$1"
  shift

  if ! contains_step "$step_name" "${steps[@]}"; then
    return 0
  fi

  if $dry_run; then
    printf 'DRY RUN [%s]:' "$step_name"
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

decide_optional_step() {
  local mode="$1"
  local prompt="$2"

  case "$mode" in
    yes)
      return 0
      ;;
    no)
      return 1
      ;;
    ask)
      if $non_interactive; then
        return 1
      fi
      if [[ ! -t 0 ]]; then
        return 1
      fi
      local reply
      read -r -p "${prompt} [y/N] " reply
      [[ "$reply" =~ ^[Yy]$ ]]
      return
      ;;
    *)
      printf 'Unknown optional step mode: %s\n' "$mode" >&2
      exit 1
      ;;
  esac
}

while (($#)); do
  case "$1" in
    --yes)
      yes_mode=true
      ;;
    --non-interactive)
      non_interactive=true
      ;;
    --dry-run)
      dry_run=true
      ;;
    --with-app-state)
      with_app_state=true
      ;;
    --defaults)
      defaults_mode="yes"
      ;;
    --skip-defaults)
      defaults_mode="no"
      ;;
    --touchid)
      touchid_mode="yes"
      ;;
    --skip-touchid)
      touchid_mode="no"
      ;;
    --skip-git)
      git_mode="no"
      ;;
    --skip-shell)
      shell_mode="no"
      ;;
    --git-name)
      shift
      git_name="${1:-}"
      ;;
    --git-email)
      shift
      git_email="${1:-}"
      ;;
    --only)
      shift
      IFS=',' read -r -a steps <<< "${1:-}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if $yes_mode; then
  [[ "$defaults_mode" == "ask" ]] && defaults_mode="yes"
  [[ "$touchid_mode" == "ask" ]] && touchid_mode="no"
fi

if $non_interactive; then
  [[ "$defaults_mode" == "ask" ]] && defaults_mode="no"
  [[ "$touchid_mode" == "ask" ]] && touchid_mode="no"
  [[ "$git_mode" == "ask" ]] && git_mode="no"
fi

for step in "${steps[@]}"; do
  case "$step" in
    xcode|brew|packages|zinit|vite|directories|link|defaults|touchid|git|shell)
      ;;
    *)
      printf 'Unknown step in --only: %s\n' "$step" >&2
      exit 1
      ;;
  esac
done

echo ""
echo "╔════════════════════════════════════╗"
echo "║   Mac Bootstrap Script v2.0        ║"
echo "╚════════════════════════════════════╝"
echo ""
echo "Selected steps: $(join_by ', ' "${steps[@]}")"
echo "App state profile: $($with_app_state && printf 'enabled' || printf 'disabled')"
echo ""

if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "This script is only for macOS" >&2
  exit 1
fi

if contains_step xcode "${steps[@]}"; then
  if $dry_run; then
    run_step xcode "${BOOTSTRAP_DIR}/install-xcode-tools.sh"
  else
    set +e
    "${BOOTSTRAP_DIR}/install-xcode-tools.sh"
    rc=$?
    set -e
    if [[ $rc -eq 20 ]]; then
      echo ""
      echo "Xcode Command Line Tools installation was started."
      echo "Finish that install, then rerun bootstrap."
      exit 0
    fi
    if [[ $rc -ne 0 ]]; then
      exit "$rc"
    fi
  fi
fi

run_step brew "${BOOTSTRAP_DIR}/install-homebrew.sh"
run_step packages "${BOOTSTRAP_DIR}/install-packages.sh" "$DOTFILES_DIR"
run_step zinit "${BOOTSTRAP_DIR}/install-zinit.sh"
run_step vite "${BOOTSTRAP_DIR}/setup-vite-plus.sh"
run_step directories "${BOOTSTRAP_DIR}/create-directories.sh"

if contains_step link "${steps[@]}"; then
  link_args=("$DOTFILES_DIR" "mac")
  $with_app_state && link_args+=("apps")
  run_step link "${BOOTSTRAP_DIR}/link-dotfiles.sh" "${link_args[@]}"
fi

if contains_step defaults "${steps[@]}" && decide_optional_step "$defaults_mode" "Apply macOS defaults?"; then
  run_step defaults "${BOOTSTRAP_DIR}/apply-macos-defaults.sh" "$DOTFILES_DIR"
fi

if contains_step touchid "${steps[@]}" && decide_optional_step "$touchid_mode" "Enable Touch ID for sudo?"; then
  run_step touchid "${BOOTSTRAP_DIR}/enable-touchid.sh" "$DOTFILES_DIR"
fi

if contains_step git "${steps[@]}"; then
  if [[ "$git_mode" == "yes" ]] || [[ "$git_mode" == "ask" ]]; then
    git_args=()
    [[ -n "$git_name" ]] && git_args+=(--name "$git_name")
    [[ -n "$git_email" ]] && git_args+=(--email "$git_email")
    $non_interactive && git_args+=(--non-interactive)
    if ((${#git_args[@]} == 0)); then
      run_step git "${BOOTSTRAP_DIR}/configure-git.sh"
    else
      run_step git "${BOOTSTRAP_DIR}/configure-git.sh" "${git_args[@]}"
    fi
  fi
fi

if contains_step shell "${steps[@]}" && [[ "$shell_mode" == "yes" ]]; then
  run_step shell "${BOOTSTRAP_DIR}/set-shell.sh"
fi

echo ""
echo "Bootstrap complete."
echo "Next useful commands:"
echo "  ./scripts/doctor.sh"
echo "  ./install mac apps"
echo ""

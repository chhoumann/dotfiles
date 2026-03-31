# Dotfiles

Automated macOS development environment setup with Homebrew, dotbot, and system preferences automation.

Read about my tools & workflows: https://bagerbach.com/blog/developer-workflow-on-windows-using-wsl-tmux-and-vscode

## Quick Start (Fresh Mac)

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone this repo
mkdir -p ~/Developer
git clone https://github.com/chhoumann/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles

# 3. Run bootstrap (installs everything!)
./bootstrap.sh
```

That's it! The bootstrap script will:
- Install Xcode Command Line Tools
- Install all packages from Brewfile (CLI tools + GUI apps)
- Install and configure Vite+ as the preferred Node runtime manager
- Create necessary directories
- Symlink the stable dotfile profiles
- Apply macOS system preferences (optional)
- Enable Touch ID for sudo (optional)
- Configure git user info

## What Gets Installed

### CLI Tools
- **Modern Unix**: `bat`, `eza`, `fzf`, `zoxide`
- **Development**: `git`, `gh`, `lazygit`
- **Languages**: `go`, `rust`, `bun`
- **Terminal**: `zellij`, `starship`, `btop`
- **Python**: `uv`
- **Utilities**: `topgrade`

Node note: bootstrap installs `Vite+` with `curl -fsSL https://vite.plus | bash`, enables managed mode, and sets the default runtime to Node LTS. There is no `mise` or `fnm` setup in this repo anymore, and Homebrew no longer installs `node`.

## Profiles

This repo now uses three installation layers:

- `default`: stable, low-churn core shell/tooling
- `mac`: macOS-specific but still stable config
- `apps`: optional high-churn editor/agent/app state

Fresh-machine bootstrap installs `default` + `mac`.

If you also want the noisier app/editor state, opt in explicitly:

```bash
cd ~/Developer/dotfiles
./install mac apps
```

That `apps` profile is where live app state such as Claude, Codex, VS Code, Cursor, and Zed lives. Keeping it separate reduces accidental repo churn.

Git identity is intentionally local now. Shared Git behavior lives in [gitconfig](/Users/christian/Developer/dotfiles/gitconfig), while per-machine identity lives in `~/.gitconfig.local`. Start from [gitconfig.local.example](/Users/christian/Developer/dotfiles/gitconfig.local.example) on new machines.

## Tool Ownership

This repo is opinionated about which tool owns which layer:

- Homebrew: system packages, GUI apps, native CLIs
- Vite+: Node runtime and global Node shims
- `uv`: Python tooling
- Cargo: Rust CLIs
- Dotbot: linking tracked config into place

If something drifts, fix it at the owning layer instead of patching around it elsewhere.

### GUI Applications
- **Productivity**: Obsidian, Notion Calendar, Raycast, Anki
- **Development**: Cursor, Zed, Ghostty, Orbstack
- **System**: Karabiner Elements, Stats, Ice
- **Media**: OBS, Spotify, Calibre, Zotero
- **Communication**: Discord

### App Configurations
All configs are version controlled and symlinked:
- Zsh (with zinit, starship, custom aliases)
- Zellij (terminal multiplexer)
- Ghostty (terminal emulator)
- Karabiner Elements (keyboard customization)
- Zed (code editor)
- Lazygit (git TUI)
- npm (`min-release-age=7`)
- uv (`exclude-newer = "7 days"`)
- Claude Code
- And more in `config/`

## Individual Commands

If you don't want to run the full bootstrap, use individual commands:

```bash
# Just install packages
brew bundle --file=~/Developer/dotfiles/Brewfile

# Just install or repair Vite+
curl -fsSL https://vite.plus | bash
eval "$("$HOME/.vite-plus/bin/vp" env print)"
vp env setup && vp env on && vp env default lts && vp env install

# Just symlink stable dotfiles
cd ~/Developer/dotfiles && ./install mac

# Include the optional app-state profile
cd ~/Developer/dotfiles && ./install mac apps

# Preview dotbot changes without executing
cd ~/Developer/dotfiles && ./install --dry-run mac

# Verify machine invariants
cd ~/Developer/dotfiles && ./scripts/doctor.sh

# Just apply macOS preferences
bash ~/Developer/dotfiles/macos/defaults.sh

# Just enable Touch ID for sudo
bash ~/Developer/dotfiles/macos/enable-touchid-sudo.sh
```

Bootstrap flags:

```bash
./bootstrap.sh --yes
./bootstrap.sh --non-interactive --git-name "Your Name" --git-email "you@example.com"
./bootstrap.sh --with-app-state
./bootstrap.sh --only brew,packages,vite,link
./bootstrap.sh --dry-run
```

## macOS System Settings

The `macos/defaults.sh` script automates these settings:

**Dock**
- Autohide enabled with no delay
- Fast animation (0.4s)
- Hide recent applications

**Finder**
- Show hidden files and all extensions
- Show path bar and status bar
- Column view by default
- Downloads as default location
- Disable file extension warning

**Trackpad**
- Tap to click enabled

**Mission Control**
- All hot corners disabled
- Don't rearrange spaces

**Screenshots**
- Save to `~/Pictures/Screenshots`
- PNG format

## Updating

```bash
# Update Homebrew packages
brew update && brew upgrade

# Or use topgrade to update everything
topgrade

# Pull latest dotfiles
cd ~/Developer/dotfiles
git pull

# Re-run symlinks if needed
./install mac

# Re-run the health checks
./scripts/doctor.sh
```

## Project Structure

```
dotfiles/
├── bootstrap.sh              # Main setup script
├── Brewfile                  # Homebrew packages
├── apps.conf.yaml            # Optional high-churn app/editor state
├── install                   # Dotbot runner
├── default.conf.yaml         # Cross-platform dotbot config
├── mac.conf.yaml            # Mac-specific dotbot config
├── macos/
│   ├── defaults.sh          # System preferences automation
│   └── enable-touchid-sudo.sh
├── scripts/
│   ├── bootstrap/           # Bootstrap step scripts
│   └── doctor.sh            # Machine invariant checks
├── config/                   # Application configs
│   ├── zellij/
│   ├── ghostty/
│   ├── topgrade/
│   ├── karabiner/
│   ├── zed/
│   └── ...
├── zshrc                    # Zsh configuration
├── zprofile                 # Login shell bootstrap
├── zprofile.local.example   # Optional machine-specific login shell extras
├── zshenv                   # Minimal shell env bootstrap
└── ...
```

## Customization

1. **Edit Brewfile**: Add/remove packages you want
2. **Edit macos/defaults.sh**: Adjust system preferences
3. **Edit zshrc**: Customize your shell
4. **Edit configs**: Modify stable app configurations in `config/`
5. **Use `~/.zprofile.local` / `~/.zshrc.local`**: Keep machine-local overrides out of tracked core config
6. **Use `~/.gitconfig.local`**: Keep machine-specific git identity out of tracked config
7. **Use `~/.config/secrets/api.env`**: Keep exported secrets like `NPM_TOKEN` out of the repo while still letting tracked config reference them

## Resources

- [Dotbot](https://github.com/anishathalye/dotbot) - Dotfiles symlinking
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle) - Package management
- [macOS defaults](https://macos-defaults.com) - System preference reference
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) - Inspiration for macOS automation

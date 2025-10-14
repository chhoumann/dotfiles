## Dotfiles
This is where I store my dotfiles.

Read about my tools & workflows: https://bagerbach.com/blog/developer-workflow-on-windows-using-wsl-tmux-and-vscode

## Quick Start (Fresh Mac)

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone this repo
mkdir -p ~/Developer
git clone https://github.com/yourusername/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles

# 3. Run bootstrap (installs everything!)
./bootstrap.sh
```

That's it! The bootstrap script will:
- Install Xcode Command Line Tools
- Install all packages from Brewfile (CLI tools + GUI apps)
- Create necessary directories
- Symlink all dotfiles to the right locations
- Apply macOS system preferences (optional)
- Enable Touch ID for sudo (optional)
- Configure git user info

## What Gets Installed

### CLI Tools
- **Modern Unix**: `bat`, `eza`, `fzf`, `zoxide`
- **Development**: `git`, `gh`, `lazygit`
- **Languages**: `go`, `node`, `rust`, `fnm`, `bun`
- **Terminal**: `zellij`, `starship`, `btop`
- **Python**: `uv`
- **Utilities**: `topgrade`

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
- Claude Code
- And more in `config/`

## Individual Commands

If you don't want to run the full bootstrap, use individual commands:

```bash
# Just install packages
brew bundle --file=~/Developer/dotfiles/Brewfile

# Just symlink dotfiles
cd ~/Developer/dotfiles && ./install mac

# Just apply macOS preferences
bash ~/Developer/dotfiles/macos/defaults.sh

# Just enable Touch ID for sudo
bash ~/Developer/dotfiles/macos/enable-touchid-sudo.sh
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
```

## Project Structure

```
dotfiles/
├── bootstrap.sh              # Main setup script
├── Brewfile                  # Homebrew packages
├── install                   # Dotbot runner
├── default.conf.yaml         # Cross-platform dotbot config
├── mac.conf.yaml            # Mac-specific dotbot config
├── macos/
│   ├── defaults.sh          # System preferences automation
│   └── enable-touchid-sudo.sh
├── config/                   # Application configs
│   ├── zellij/
│   ├── ghostty/
│   ├── karabiner/
│   ├── zed/
│   └── ...
├── zshrc                    # Zsh configuration
└── ...
```

## Customization

1. **Edit Brewfile**: Add/remove packages you want
2. **Edit macos/defaults.sh**: Adjust system preferences
3. **Edit zshrc**: Customize your shell
4. **Edit configs**: Modify app configurations in `config/`

## Resources

- [Dotbot](https://github.com/anishathalye/dotbot) - Dotfiles symlinking
- [Homebrew Bundle](https://github.com/Homebrew/homebrew-bundle) - Package management
- [macOS defaults](https://macos-defaults.com) - System preference reference
- [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) - Inspiration for macOS automation

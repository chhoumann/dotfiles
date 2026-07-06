# Dotfiles Brewfile
# Install everything with: brew bundle --file=~/Developer/dotfiles/Brewfile
#
# Use canonical formula/cask names (no aliases), or scripts/brew-drift.sh
# reports false drift. Machine-local packages that aren't part of the
# portable setup go in Brewfile.local (gitignored, same syntax).

# Taps
tap "chhoumann/tap"
tap "chhoumann/wribe"
tap "openclaw/tap"
tap "jnsahaj/lumen"
tap "steipete/tap"

# ============================================================
# Command-line Tools
# ============================================================

# Modern Unix replacements
brew "atuin"            # Better shell history
brew "bat"              # Better cat
brew "dust"             # Better du
brew "eza"              # Better ls
brew "fd"               # Better find
brew "fzf"              # Fuzzy finder
brew "ripgrep"          # Better grep
brew "xh"               # Better curl
brew "zoxide"           # Better cd

# File managers & navigation
brew "tree"             # Directory tree viewer
brew "yazi"             # Terminal file manager
brew "walk"             # Terminal navigator

# Development tools
brew "ast-grep"         # Code search/lint/rewrite
brew "git-delta"        # Better git diffs
brew "gh"               # GitHub CLI
brew "git"              # Version control
brew "openclaw/tap/gogcli", trusted: true # Google CLI (gog)
brew "jnsahaj/lumen/lumen", trusted: true # AI git diffs (ld)
brew "graphviz"         # Graph visualization
brew "hyperfine"        # CLI benchmarking
brew "jq"               # JSON processor
brew "lazygit"          # Git TUI
brew "shellcheck"       # Shell script linting
brew "shfmt"            # Shell script formatter
brew "xcodegen"         # Xcode project generator

# Languages & runtimes
brew "go"               # Go language
brew "rust"             # Rust language
brew "zig"              # Zig language
brew "openjdk@11"       # Java 11
brew "swiftformat"      # Swift formatter
brew "swig"             # Wrapper generator
brew "premake"          # Build configuration
brew "cmake"            # Build system

# Terminal & shell
brew "tmux"             # Terminal multiplexer
brew "zellij"           # Terminal multiplexer
brew "starship"         # Shell prompt
brew "btop"             # System monitor

# Python tooling
brew "uv"               # Fast Python package installer

# Web & cloud
brew "caddy"            # Web server
brew "cloudflare-wrangler" # Cloudflare Workers CLI
brew "helm"             # Kubernetes package manager
brew "k9s"              # Kubernetes TUI
brew "vercel-cli"       # Vercel deployment

# Media
brew "ffmpeg"           # Video/audio processing
brew "yt-dlp"           # YouTube downloader
brew "jpeg"             # JPEG image library

# Utilities
brew "direnv"           # Per-directory env vars
brew "topgrade"         # Update everything
brew "languagetool"     # Grammar checker
brew "pandoc"           # Document converter
brew "chhoumann/tap/uca", trusted: true # Update multiple coding-agent CLIs with one command

# ============================================================
# GUI Applications (Casks)
# ============================================================

# Productivity & Organization
cask "obsidian"         # Note-taking
cask "notion-calendar"  # Calendar
cask "raycast"          # Launcher
cask "anki"             # Flashcards

# Development
cask "cursor"           # AI Code editor
cask "visual-studio-code" # Code editor
cask "zed"              # Code editor
cask "ghostty"          # Terminal emulator
cask "orbstack"         # Docker alternative
cask "beekeeper-studio" # Database GUI
cask "insomnia"         # API client
cask "mitmproxy"        # HTTP debugging proxy
cask "ngrok"            # HTTP tunneling
cask "devtoys"          # Developer utilities
cask "steipete/tap/codexbar", trusted: true # Menu bar AI usage

# System utilities
cask "karabiner-elements"  # Keyboard customization
cask "stats"               # Menu bar system monitor
cask "jordanbaird-ice@beta" # Menu bar manager
cask "tailscale-app"       # VPN mesh networking

# Media & Content
cask "iina"             # Media player
cask "obs"              # Screen recording
cask "spotify"          # Music
cask "calibre"          # E-book manager
cask "zotero"           # Reference manager

# Communication
cask "discord"          # Chat

# Browsers
cask "google-chrome"    # Web browser

# ============================================================
# Optional - Apps to consider
# ============================================================

cask "mac-mouse-fix"  # Better mouse
cask "chhoumann/wribe/wribe", trusted: true # AI transcription
cask "temurin@11"     # Java 11 runtime

cask "cleanshot"      # Screenshots
cask "clop"           # Image optimizer (free)
cask "screen-studio"  # Screen recording

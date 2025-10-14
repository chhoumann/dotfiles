#!/usr/bin/env bash

#############################################
# Mac Bootstrap Script
#############################################
# Automates setup of a new Mac
# Run with: bash ~/Developer/dotfiles/bootstrap.sh

set -e  # Exit on error

echo ""
echo "╔════════════════════════════════════╗"
echo "║   Mac Bootstrap Script v1.0        ║"
echo "╚════════════════════════════════════╝"
echo ""

# Get the directory where this script is located
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#############################################
# Check if running on macOS
#############################################

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is only for macOS"
    exit 1
fi

#############################################
# 1. Install Xcode Command Line Tools
#############################################

install_xcode_tools() {
    echo "📦 Installing Xcode Command Line Tools..."

    if xcode-select -p &>/dev/null; then
        echo "✅ Xcode Command Line Tools already installed"
    else
        xcode-select --install
        echo ""
        echo "⏳ Please complete the Xcode installation dialog, then run this script again"
        echo ""
        exit 0
    fi
}

#############################################
# 2. Install Homebrew
#############################################

install_homebrew() {
    echo "🍺 Installing Homebrew..."

    if command -v brew &>/dev/null; then
        echo "✅ Homebrew already installed"
        echo "📦 Updating Homebrew..."
        brew update
    else
        echo "📥 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon
        if [[ $(uname -m) == "arm64" ]]; then
            echo ""
            echo "🔧 Adding Homebrew to PATH for Apple Silicon..."
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi

        echo "✅ Homebrew installed"
    fi

    echo ""
}

#############################################
# 3. Install packages from Brewfile
#############################################

install_packages() {
    echo "📦 Installing packages from Brewfile..."
    echo ""

    if [ -f "$DOTFILES_DIR/Brewfile" ]; then
        brew bundle --file="$DOTFILES_DIR/Brewfile"
        echo ""
        echo "✅ Packages installed"
    else
        echo "⚠️  No Brewfile found at $DOTFILES_DIR/Brewfile"
    fi

    echo ""
}

#############################################
# 4. Create necessary directories
#############################################

create_directories() {
    echo "📁 Creating directories..."

    directories=(
        "$HOME/.config"
        "$HOME/Developer"
        "$HOME/Pictures/Screenshots"
    )

    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "  ✅ Created: $dir"
        else
            echo "  ✅ Already exists: $dir"
        fi
    done

    echo ""
}

#############################################
# 5. Symlink dotfiles using dotbot
#############################################

symlink_dotfiles() {
    echo "🔗 Symlinking dotfiles with dotbot..."
    echo ""

    cd "$DOTFILES_DIR"

    # Determine which config to use based on platform
    if [ -f "$DOTFILES_DIR/install" ]; then
        # Run dotbot with default and mac configs
        "$DOTFILES_DIR/install" mac
        echo ""
        echo "✅ Dotfiles symlinked"
    else
        echo "⚠️  No dotbot install script found"
    fi

    echo ""
}

#############################################
# 6. Apply macOS defaults
#############################################

apply_macos_defaults() {
    echo "⚙️  Apply macOS system preferences?"
    echo "   This will configure Dock, Finder, Trackpad, etc."
    read -p "   Apply? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$DOTFILES_DIR/macos/defaults.sh" ]; then
            bash "$DOTFILES_DIR/macos/defaults.sh"
        else
            echo "⚠️  No macos defaults script found"
        fi
    else
        echo "⏭️  Skipping macOS defaults"
    fi

    echo ""
}

#############################################
# 7. Enable Touch ID for sudo
#############################################

enable_touchid_sudo() {
    echo "🔐 Enable Touch ID for sudo?"
    echo "   This allows you to use Touch ID instead of typing your password for sudo"
    read -p "   Enable? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$DOTFILES_DIR/macos/enable-touchid-sudo.sh" ]; then
            bash "$DOTFILES_DIR/macos/enable-touchid-sudo.sh"
        else
            echo "⚠️  Touch ID script not found"
        fi
    else
        echo "⏭️  Skipping Touch ID setup"
    fi

    echo ""
}

#############################################
# 8. Configure git
#############################################

configure_git() {
    echo "🔧 Configuring git..."

    # Check if git is installed
    if ! command -v git &>/dev/null; then
        echo "⚠️  Git not installed, skipping"
        echo ""
        return
    fi

    # Prompt for user info if not set
    if [ -z "$(git config --global user.name)" ]; then
        echo ""
        read -p "Enter your full name for git: " git_name
        git config --global user.name "$git_name"
        echo "✅ Set git user.name"
    else
        echo "✅ Git user.name already set: $(git config --global user.name)"
    fi

    if [ -z "$(git config --global user.email)" ]; then
        echo ""
        read -p "Enter your email for git: " git_email
        git config --global user.email "$git_email"
        echo "✅ Set git user.email"
    else
        echo "✅ Git user.email already set: $(git config --global user.email)"
    fi

    # Set up gh as git credential helper if available
    if command -v gh &>/dev/null; then
        echo "🔐 Configuring GitHub CLI as git credential helper..."
        gh auth setup-git 2>/dev/null || true
        echo "✅ Git credentials configured"
    fi

    echo ""
}

#############################################
# 9. Set default shell
#############################################

set_shell() {
    echo "🐚 Setting default shell to zsh..."

    desired_shell="/bin/zsh"

    if [ "$SHELL" != "$desired_shell" ]; then
        if ! grep -q "$desired_shell" /etc/shells; then
            echo "$desired_shell" | sudo tee -a /etc/shells
        fi
        chsh -s "$desired_shell"
        echo "✅ Shell changed to $desired_shell (restart terminal to apply)"
    else
        echo "✅ Shell already set to $desired_shell"
    fi

    echo ""
}

#############################################
# Main execution
#############################################

main() {
    echo "🚀 Starting Mac bootstrap..."
    echo ""

    # Run installation steps
    install_xcode_tools
    install_homebrew
    install_packages
    create_directories
    symlink_dotfiles
    apply_macos_defaults
    enable_touchid_sudo
    configure_git
    set_shell

    echo ""
    echo "╔════════════════════════════════════╗"
    echo "║   ✨ Bootstrap Complete! ✨        ║"
    echo "╚════════════════════════════════════╝"
    echo ""
    echo "📝 Next steps:"
    echo "  1. Restart your terminal (or run: exec zsh)"
    echo "  2. Install 1Password and sign in"
    echo "  3. Install a browser (Zen, Arc, etc.)"
    echo "  4. Install Claude Code: bun add -g @anthropic-ai/claude-code"
    echo "  5. Review and adjust any settings as needed"
    echo ""
    echo "📖 See the setup guide for more manual steps:"
    echo "   https://github.com/yourusername/dotfiles#manual-setup"
    echo ""
}

# Run main function
main

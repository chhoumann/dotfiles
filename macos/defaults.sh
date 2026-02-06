#!/usr/bin/env bash

#############################################
# macOS System Preferences Automation
#############################################
# Based on: https://github.com/mathiasbynens/dotfiles/blob/main/.macos
# Run with: bash ~/Developer/dotfiles/macos/defaults.sh

set -e

echo "🍎 Configuring macOS system preferences..."
echo ""

# Close any open System Preferences panes to prevent overriding settings
osascript -e 'tell application "System Preferences" to quit'

# Ask for administrator password upfront
sudo -v

# Keep sudo alive until script is finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

#############################################
# Dock
#############################################

echo "⚙️  Configuring Dock..."

# Enable autohide
defaults write com.apple.dock autohide -bool true

# Remove autohide delay (show immediately on hover)
defaults write com.apple.dock autohide-delay -int 0

# Speed up autohide animation (0.4 seconds)
defaults write com.apple.dock autohide-time-modifier -float 0.4

# Show indicators for open applications
defaults write com.apple.dock show-process-indicators -bool true

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Make hidden app icons translucent
defaults write com.apple.dock showhidden -bool true

#############################################
# Finder
#############################################

echo "⚙️  Configuring Finder..."

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show path bar at bottom
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar at bottom
defaults write com.apple.finder ShowStatusBar -bool true

# Show full POSIX path in title bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Disable warning when changing file extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Use column view by default
# Options: `icnv` (icon), `Nlsv` (list), `clmv` (column), `Flwv` (cover flow)
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Set default location for new Finder windows to Downloads
# Options: `PfDe` (Desktop), `PfDo` (Documents), `PfHm` (Home), or `PfLo` (Other + NewWindowTargetPath)
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Unhide ~/Library folder
chflags nohidden ~/Library

# Unhide /Volumes folder
sudo chflags nohidden /Volumes 2>/dev/null || true

#############################################
# Trackpad
#############################################

echo "⚙️  Configuring Trackpad..."

# Enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

#############################################
# Mission Control & Hot Corners
#############################################

echo "⚙️  Configuring Mission Control..."

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Disable all hot corners
# Corners: wvous-tl (top-left), wvous-tr (top-right), wvous-bl (bottom-left), wvous-br (bottom-right)
# Values: 0 = disabled
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 0
defaults write com.apple.dock wvous-br-modifier -int 0

#############################################
# Screenshots
#############################################

echo "⚙️  Configuring Screenshots..."

# Save screenshots to Pictures folder
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"

# Save screenshots in PNG format
defaults write com.apple.screencapture type -string "png"

#############################################
# Restart affected applications
#############################################

echo ""
echo "✅ macOS preferences configured!"
echo ""
echo "🔄 Restarting affected applications..."

killall Dock
killall Finder
killall SystemUIServer

echo ""
echo "✨ Done! Some changes may require a logout or restart to take effect."
echo ""

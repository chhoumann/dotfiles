#!/usr/bin/env bash

#############################################
# Enable Touch ID for sudo
#############################################
# This script enables Touch ID authentication for sudo commands
# Works on macOS Sonoma (14+) and later
# Changes persist through system updates

set -e

echo "🔐 Enabling Touch ID for sudo..."

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is only for macOS"
    exit 1
fi

# Check if sudo_local already exists
if [ ! -f /etc/pam.d/sudo_local ]; then
    echo "📝 Creating /etc/pam.d/sudo_local..."
    sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
    echo "✅ Created /etc/pam.d/sudo_local"
else
    echo "✅ /etc/pam.d/sudo_local already exists"
fi

# Check if Touch ID is already enabled
if sudo grep -q "^auth.*pam_tid.so" /etc/pam.d/sudo_local; then
    echo "✅ Touch ID for sudo is already enabled"
else
    echo "🔧 Enabling Touch ID..."
    # Uncomment the pam_tid.so line
    sudo sed -i '' 's/^#auth\(.*pam_tid\.so\)/auth\1/' /etc/pam.d/sudo_local
    echo "✅ Touch ID for sudo has been enabled"
fi

echo ""
echo "✨ Done! Test with: sudo echo 'Hello'"
echo ""
echo "ℹ️  Note: Touch ID won't work inside tmux sessions"

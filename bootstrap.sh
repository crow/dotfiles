#!/bin/bash
set -e

echo "=== Dotfiles Bootstrap ==="
echo "This script sets up a new machine with chezmoi + age encryption"
echo ""

# Install chezmoi if not present
if ! command -v chezmoi &> /dev/null; then
    echo "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)"
    export PATH="$HOME/bin:$PATH"
fi

# Install age if not present
if ! command -v age &> /dev/null; then
    echo "Installing age..."
    brew install age
fi

# Init from GitHub (runs before-scripts: installs brew, omz)
echo "Initializing chezmoi from GitHub..."
chezmoi init jdavidcrow --ssh

# Prompt for age key
echo ""
echo "Place your age key file at ~/.config/chezmoi/key.txt"
echo "  (copy it from your existing machine or password manager)"
read -p "Press Enter when key.txt is in place..."

if [ ! -f "$HOME/.config/chezmoi/key.txt" ]; then
    echo "ERROR: key.txt not found at ~/.config/chezmoi/key.txt"
    exit 1
fi

# Apply all dotfiles
echo ""
echo "Applying dotfiles..."
chezmoi apply -v

echo ""
echo "=== Bootstrap complete! ==="
echo "Run 'exec zsh' to reload your shell."

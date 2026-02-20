#!/bin/bash
set -e

echo "=== Dotfiles Bootstrap ==="
echo "This script sets up a new machine with chezmoi + LastPass"
echo ""

# Install chezmoi if not present
if ! command -v chezmoi &> /dev/null; then
    echo "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)"
    export PATH="$HOME/bin:$PATH"
fi

# Init from GitHub (runs before-scripts: installs brew, lpass, omz)
echo "Initializing chezmoi from GitHub..."
chezmoi init jdavidcrow --ssh

# Login to LastPass (interactive)
echo ""
echo "Please log in to LastPass to decrypt secrets:"
lpass login jdavidcrow@gmail.com

# Apply all dotfiles
echo ""
echo "Applying dotfiles..."
chezmoi apply -v

echo ""
echo "=== Bootstrap complete! ==="
echo "Run 'exec zsh' to reload your shell."

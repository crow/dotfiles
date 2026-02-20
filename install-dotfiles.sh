#!/bin/bash

# --- helpers ---
step() { echo ""; echo "[$1/$TOTAL_STEPS] $2"; }
info() { echo "  $1"; }
success() { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
die() { echo ""; echo "ERROR: $1"; exit 1; }

TOTAL_STEPS=4

echo "=== Dotfiles Installer ==="
echo "Sets up this machine with your dotfiles, shell config, and secrets"

# Step 1: Homebrew
step 1 "Homebrew"
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || die "Homebrew install failed"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    success "Already installed"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" 2>/dev/null || true

# Step 2: chezmoi + age
step 2 "chezmoi + age"
command -v chezmoi &>/dev/null || brew install chezmoi || die "chezmoi install failed"
command -v age &>/dev/null || brew install age || die "age install failed"
success "Ready"

# Step 3: Age decryption key
step 3 "Age decryption key"
mkdir -p "$HOME/.config/chezmoi"
if [ -f "$HOME/.config/chezmoi/key.txt" ]; then
    success "Key already exists at ~/.config/chezmoi/key.txt"
else
    info "Your dotfiles are encrypted. You need your age key to decrypt them."
    echo ""
    echo "    a) Paste the key now"
    echo "    b) Place key.txt at ~/.config/chezmoi/key.txt manually"
    echo ""
    read -p "  Choose (a/b): " key_choice
    if [[ "$key_choice" == "a" ]]; then
        echo ""
        info "Paste your age key (starts with AGE-SECRET-KEY-), then Enter + Ctrl-D:"
        echo ""
        cat > "$HOME/.config/chezmoi/key.txt"
        chmod 600 "$HOME/.config/chezmoi/key.txt"
        success "Key saved."
    else
        echo ""
        read -p "  Press Enter when key.txt is in place..."
    fi
    [ -f "$HOME/.config/chezmoi/key.txt" ] || die "key.txt not found at ~/.config/chezmoi/key.txt"
fi

# Step 4: Init and apply dotfiles
# chezmoi will prompt for profile (personal/work/bot) and handle everything else
step 4 "Initializing dotfiles"
if chezmoi init --apply crow --ssh 2>/dev/null; then
    success "Done (via SSH)"
else
    warn "SSH failed, trying HTTPS..."
    chezmoi init --apply https://github.com/crow/dotfiles.git || die "chezmoi init failed"
    success "Done (via HTTPS)"
fi

echo ""
echo "=== All done! ==="
echo "Run 'exec zsh' to start using your new shell."

#!/bin/bash

# --- helpers ---
step() { echo ""; echo "[$1/$TOTAL_STEPS] $2"; }
info() { echo "  $1"; }
success() { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
die() { echo ""; echo "ERROR: $1"; exit 1; }

TOTAL_STEPS=5

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
CHEZMOI_DIR="$HOME/.local/share/chezmoi"
if [ -d "$CHEZMOI_DIR/.git" ]; then
    existing_remote=$(git -C "$CHEZMOI_DIR" remote get-url origin 2>/dev/null || echo "unknown")
    if echo "$existing_remote" | grep -q "crow/dotfiles"; then
        success "Correct repo already present"
    else
        warn "Wrong repo at $CHEZMOI_DIR (remote: $existing_remote)"
        warn "Backing up to ${CHEZMOI_DIR}.bak and re-cloning..."
        mv "$CHEZMOI_DIR" "${CHEZMOI_DIR}.bak"
    fi
fi

if chezmoi init --apply crow --ssh 2>/dev/null; then
    success "Done (via SSH)"
else
    warn "SSH failed, trying HTTPS..."
    chezmoi init --apply https://github.com/crow/dotfiles.git || die "chezmoi init failed"
    success "Done (via HTTPS)"
fi

# Step 5: SSH key (optional)
step 5 "SSH key setup"
if ls "$HOME/.ssh/id_"* &>/dev/null; then
    info "SSH keys already exist:"
    ls -1 "$HOME/.ssh/id_"* 2>/dev/null | sed 's/^/    /'
    echo ""
    read -p "  Generate a new key anyway? (y/n): " ssh_new
    [[ "$ssh_new" == "y" ]] || { echo ""; echo "=== All done! ==="; echo "Run 'exec zsh' to start using your new shell."; exit 0; }
else
    read -p "  Would you like to set up an SSH key? (y/n): " ssh_setup
    [[ "$ssh_setup" == "y" ]] || { echo ""; echo "=== All done! ==="; echo "Run 'exec zsh' to start using your new shell."; exit 0; }
fi

echo ""
read -p "  Key name (default: id_ed25519): " ssh_name
ssh_name="${ssh_name:-id_ed25519}"
ssh_path="$HOME/.ssh/$ssh_name"

if [ -f "$ssh_path" ]; then
    info "$ssh_path already exists. Skipping keygen."
else
    read -p "  Email for key label (default: git config email): " ssh_email
    [[ -z "$ssh_email" ]] && ssh_email=$(git config --global user.email 2>/dev/null || echo "")
    echo ""
    info "Generating ed25519 key at $ssh_path..."
    if [[ -n "$ssh_email" ]]; then
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$ssh_path" || die "ssh-keygen failed"
    else
        ssh-keygen -t ed25519 -f "$ssh_path" || die "ssh-keygen failed"
    fi
fi

info "Adding key to SSH agent..."
eval "$(ssh-agent -s)" >/dev/null 2>&1
ssh-add --apple-use-keychain "$ssh_path" 2>/dev/null || ssh-add "$ssh_path"

echo ""
info "Your public key:"
echo "  ─────────────────────────────────"
cat "${ssh_path}.pub"
echo "  ─────────────────────────────────"
echo ""

read -p "  Copy public key to clipboard? (y/n): " copy_key
[[ "$copy_key" == "y" ]] && pbcopy < "${ssh_path}.pub" && info "Copied! Paste it into GitHub, servers, etc."

read -p "  Open GitHub SSH settings in browser? (y/n): " open_gh
[[ "$open_gh" == "y" ]] && open "https://github.com/settings/ssh/new"

echo ""
echo "=== All done! ==="
echo "Run 'exec zsh' to start using your new shell."

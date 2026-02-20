#!/bin/bash

# --- helpers ---
step() { echo ""; echo "[$1/$TOTAL_STEPS] $2"; }
info() { echo "  $1"; }
success() { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
die() { echo ""; echo "ERROR: $1"; exit 1; }

TOTAL_STEPS=7

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
# Ensure brew is in PATH for the rest of this script
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" 2>/dev/null || true

# Step 2: chezmoi
step 2 "chezmoi"
if ! command -v chezmoi &>/dev/null; then
    info "Installing chezmoi..."
    brew install chezmoi || die "chezmoi install failed"
else
    success "Already installed"
fi

# Step 3: age
step 3 "age"
if ! command -v age &>/dev/null; then
    info "Installing age..."
    brew install age || die "age install failed"
else
    success "Already installed"
fi

# Step 4: age key + chezmoi config
step 4 "Age decryption key"
mkdir -p "$HOME/.config/chezmoi"

# Write chezmoi.toml FIRST so chezmoi never tries to prompt from the template
cat > "$HOME/.config/chezmoi/chezmoi.toml" <<'EOF'
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1yaa0vvhceuc8p4ugenhmqgpzrffsew7ejnthyjzsj5nvgexqjcus7a60la"

[git]
    autoCommit = true
    autoPush = true

[data]
    name = "David"
    email = "jdavidcrow@gmail.com"
EOF
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

# Step 5: clone + apply dotfiles
step 5 "Cloning and applying dotfiles"
CHEZMOI_DIR="$HOME/.local/share/chezmoi"

# Check if something is already at the chezmoi dir
if [ -d "$CHEZMOI_DIR" ]; then
    if [ -d "$CHEZMOI_DIR/.git" ]; then
        existing_remote=$(git -C "$CHEZMOI_DIR" remote get-url origin 2>/dev/null || echo "unknown")
    else
        existing_remote="unknown (not a git repo)"
    fi

    if echo "$existing_remote" | grep -q "crow/dotfiles"; then
        success "Correct repo already cloned, pulling latest..."
        chezmoi git pull || warn "Git pull failed, continuing with existing files"
        chezmoi apply -v || die "chezmoi apply failed"
    else
        warn "Something already exists at ~/.local/share/chezmoi/"
        info "Contents: $(ls "$CHEZMOI_DIR" | head -5 | tr '\n' ' ')..."
        [ "$existing_remote" != "unknown (not a git repo)" ] && info "Remote: $existing_remote"
        echo ""
        read -p "  Overwrite it? It will be backed up to ~/.local/share/chezmoi.bak (y/n): " overwrite
        if [[ "$overwrite" == "y" ]]; then
            mv "$CHEZMOI_DIR" "${CHEZMOI_DIR}.bak"
            success "Backed up to ~/.local/share/chezmoi.bak"
        else
            die "Cancelled. Remove ~/.local/share/chezmoi manually and re-run."
        fi
    fi
fi

# Clone if not present
if [ ! -d "$CHEZMOI_DIR/.git" ]; then
    info "Trying SSH..."
    if chezmoi init crow --ssh 2>/dev/null; then
        success "Cloned via SSH"
    else
        warn "SSH failed, falling back to HTTPS..."
        chezmoi init https://github.com/crow/dotfiles.git || die "chezmoi init failed via both SSH and HTTPS"
        success "Cloned via HTTPS"
    fi
fi

# Ensure chezmoi.toml exists (init may not create it if template prompts failed)
CHEZMOI_CFG="$HOME/.config/chezmoi/chezmoi.toml"
if [ ! -f "$CHEZMOI_CFG" ]; then
    warn "chezmoi.toml missing -- creating from known config"
    mkdir -p "$HOME/.config/chezmoi"
    cat > "$CHEZMOI_CFG" <<'EOF'
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1yaa0vvhceuc8p4ugenhmqgpzrffsew7ejnthyjzsj5nvgexqjcus7a60la"

[git]
    autoCommit = true
    autoPush = true

[data]
    name = "David"
    email = "jdavidcrow@gmail.com"
EOF
    success "chezmoi.toml created"
fi

chezmoi apply -v || die "chezmoi apply failed"

# Step 6: brew packages
step 6 "Installing packages from Brewfile"
brewfile="$HOME/.local/share/chezmoi/Brewfile"
if [ ! -f "$brewfile" ]; then
    warn "Brewfile not in local chezmoi dir, downloading from GitHub..."
    brewfile=$(mktemp)
    curl -fsSL "https://raw.githubusercontent.com/crow/dotfiles/main/Brewfile" -o "$brewfile" || { warn "Could not download Brewfile, skipping packages"; brewfile=""; }
fi
if [ -n "$brewfile" ] && [ -f "$brewfile" ]; then
    brew bundle --file="$brewfile" --no-lock || warn "Some packages failed -- run 'brew bundle --file=~/.local/share/chezmoi/Brewfile' to retry"
fi

# Step 7: SSH key
step 7 "SSH key setup"
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

#!/bin/bash
set -e

echo "=== Dotfiles Installer ==="
echo "Sets up this machine with your dotfiles, shell config, and secrets"
echo ""

# Step 1: Homebrew
if ! command -v brew &> /dev/null; then
    echo "[1/5] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "[1/5] Homebrew already installed"
fi

# Step 2: chezmoi
if ! command -v chezmoi &> /dev/null; then
    echo "[2/5] Installing chezmoi..."
    brew install chezmoi
else
    echo "[2/5] chezmoi already installed"
fi

# Step 3: age
if ! command -v age &> /dev/null; then
    echo "[3/5] Installing age..."
    brew install age
else
    echo "[3/5] age already installed"
fi

# Step 4: age key
echo ""
echo "[4/5] Age decryption key"
mkdir -p "$HOME/.config/chezmoi"

if [ -f "$HOME/.config/chezmoi/key.txt" ]; then
    echo "  Key already exists at ~/.config/chezmoi/key.txt"
else
    echo "  Your dotfiles are encrypted. You need your age key to decrypt them."
    echo ""
    echo "  Options:"
    echo "    a) Paste the key contents now"
    echo "    b) Place key.txt at ~/.config/chezmoi/key.txt manually"
    echo ""
    read -p "  Choose (a/b): " key_choice

    if [[ "$key_choice" == "a" ]]; then
        echo ""
        echo "  Paste your age key below (starts with AGE-SECRET-KEY-),"
        echo "  then press Enter followed by Ctrl-D:"
        echo ""
        cat > "$HOME/.config/chezmoi/key.txt"
        chmod 600 "$HOME/.config/chezmoi/key.txt"
        echo ""
        echo "  Key saved."
    else
        echo ""
        read -p "  Press Enter when key.txt is in place..."
    fi

    if [ ! -f "$HOME/.config/chezmoi/key.txt" ]; then
        echo "  ERROR: key.txt not found. Cannot continue without it."
        exit 1
    fi
fi

# Step 5: chezmoi init + apply
echo ""
echo "[5/5] Cloning and applying dotfiles..."
chezmoi init crow --ssh --apply -v

# Step 6: Optional SSH key setup
echo ""
echo "[6/6] SSH key setup"

if ls "$HOME/.ssh/id_"* &>/dev/null; then
    echo "  SSH keys already exist:"
    ls -1 "$HOME/.ssh/id_"* 2>/dev/null | sed 's/^/    /'
    echo ""
    read -p "  Generate a new key anyway? (y/n): " ssh_new
    if [[ "$ssh_new" != "y" ]]; then
        echo "  Skipping SSH setup."
        echo ""
        echo "=== All done! ==="
        echo "Run 'exec zsh' to start using your new shell."
        exit 0
    fi
else
    read -p "  Would you like to set up an SSH key? (y/n): " ssh_setup
    if [[ "$ssh_setup" != "y" ]]; then
        echo "  Skipping SSH setup."
        echo ""
        echo "=== All done! ==="
        echo "Run 'exec zsh' to start using your new shell."
        exit 0
    fi
fi

echo ""
read -p "  Key name (default: id_ed25519): " ssh_name
ssh_name="${ssh_name:-id_ed25519}"
ssh_path="$HOME/.ssh/$ssh_name"

if [ -f "$ssh_path" ]; then
    echo "  $ssh_path already exists. Skipping."
else
    read -p "  Email for key label (default: git config email): " ssh_email
    if [[ -z "$ssh_email" ]]; then
        ssh_email=$(git config --global user.email 2>/dev/null || echo "")
    fi

    echo ""
    echo "  Generating ed25519 key at $ssh_path..."
    if [[ -n "$ssh_email" ]]; then
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$ssh_path"
    else
        ssh-keygen -t ed25519 -f "$ssh_path"
    fi
fi

# Add to agent
echo ""
echo "  Adding key to SSH agent..."
eval "$(ssh-agent -s)" >/dev/null 2>&1
ssh-add --apple-use-keychain "$ssh_path" 2>/dev/null || ssh-add "$ssh_path"

# Offer to copy public key
echo ""
echo "  Your public key:"
echo "  ─────────────────────────────────"
cat "${ssh_path}.pub"
echo "  ─────────────────────────────────"
echo ""

read -p "  Copy public key to clipboard? (y/n): " copy_key
if [[ "$copy_key" == "y" ]]; then
    pbcopy < "${ssh_path}.pub"
    echo "  Copied! Paste it into GitHub, servers, etc."
fi

read -p "  Open GitHub SSH settings in browser? (y/n): " open_gh
if [[ "$open_gh" == "y" ]]; then
    open "https://github.com/settings/ssh/new"
fi

echo ""
echo "=== All done! ==="
echo "Run 'exec zsh' to start using your new shell."

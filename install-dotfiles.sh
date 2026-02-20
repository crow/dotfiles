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

echo ""
echo "=== All done! ==="
echo "Run 'exec zsh' to start using your new shell."

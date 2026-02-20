# General utilities

# Refreshes the current shell environment
function refresh() {
    source ~/.zshrc
    exec zsh
}

# Creates a .webloc link file on the Desktop
function genlinkfile {
    echo "Enter the URL for the link file:"
    read url
    echo "Creating a .webloc file on the Desktop..."
    osascript -e "set theURL to \"$url\"" \
             -e "set thePath to (path to desktop folder as text) & \"LinkFile.webloc\"" \
             -e "tell application \"Finder\"" \
             -e "make new internet location file at desktop to theURL with properties {name:\"LinkFile\"}" \
             -e "end tell"
    echo "Done! 'LinkFile.webloc' created on Desktop."
}

# Interactive chezmoi file editor
# Lists managed files, lets you pick one to edit, then applies changes
function chezmoi-edit() {
    local files=()
    local i=1

    echo "Chezmoi managed files:"
    echo "─────────────────────────────────"

    while IFS= read -r file; do
        files+=("$file")
        printf "  %2d) %s\n" "$i" "$file"
        ((i++))
    done < <(chezmoi managed --include=files | sort)

    echo "─────────────────────────────────"
    echo "  q) Quit"
    echo ""

    local choice
    read "choice?Select a file to edit: "

    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo "Cancelled."
        return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#files[@]} )); then
        echo "Invalid selection."
        return 1
    fi

    local target="${files[$choice]}"
    echo ""
    echo "Opening: $target"
    chezmoi edit "$HOME/$target"

    echo ""
    read "?Press Enter when done editing to apply changes (or Ctrl-C to cancel)..."
    echo ""
    echo "Applying changes..."
    chezmoi apply -v
    echo ""
    echo "Done! Changes applied."
}

# PGP key paths
export PGP_PUBLIC_KEY_PATH="$HOME/pgp/publickey.asc"
export PGP_PRIVATE_KEY_PATH="$HOME/pgp/privatekey.asc"

# Decrypts clipboard PGP message
pgpread() {
    if [ -f $HOME/pgp/.env ]; then
        set -a
        source $HOME/pgp/.env
        set +a
    else
        echo ".env file not found."
        return 1
    fi

    gpg --import $PGP_PRIVATE_KEY_PATH &> /dev/null

    decrypted_message=$(pbpaste | gpg --batch --yes --passphrase "$GPG_PASSPHRASE" --decrypt 2>/dev/null)

    if [ $? -eq 0 ]; then
        echo "$decrypted_message" | pbcopy
        echo "Decrypted message:"
        echo "$decrypted_message"
    else
        echo "Failed to decrypt the message. Ensure your private key and passphrase are correct."
    fi
}

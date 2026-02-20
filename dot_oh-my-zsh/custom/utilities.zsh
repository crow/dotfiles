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
    echo "   0) Add secret key (opens .zshrc)"

    while IFS= read -r file; do
        files+=("$file")
        printf "  %2d) %s\n" "$i" "$file"
        ((i++))
    done < <(chezmoi managed --include=files | sort)

    echo "─────────────────────────────────"
    echo "   q) Quit"
    echo ""

    local choice
    read "choice?Select a file to edit: "

    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo "Cancelled."
        return 0
    fi

    local target
    if [[ "$choice" == "0" ]]; then
        target=".zshrc"
        local secret_value=$(pbpaste 2>/dev/null)

        if [[ -z "$secret_value" ]]; then
            echo "Clipboard is empty. Copy your secret first."
            return 1
        fi

        # Parse clipboard -- handle KEY=value, export KEY="value", or raw value
        local key_name=""
        local key_value=""
        if [[ "$secret_value" =~ ^(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=[\"\']?(.+?)[\"\']?$ ]]; then
            key_name="${match[2]}"
            key_value="${match[3]}"
        else
            key_value="$secret_value"
        fi

        # Show what we found
        echo ""
        if [[ -n "$key_name" ]]; then
            echo "Detected: $key_name"
        else
            echo "Clipboard value: ${key_value:0:20}..."
            read "key_name?Enter variable name (e.g. OPENAI_API_KEY): "
            if [[ -z "$key_name" ]]; then
                echo "No name provided. Cancelled."
                return 1
            fi
        fi

        # Confirm
        echo ""
        echo "Will add to .zshrc:"
        echo "  export ${key_name}=\"${key_value:0:20}...\""
        echo ""
        local confirm
        read "confirm?Proceed? (y/n): "
        if [[ "$confirm" != "y" ]]; then
            echo "Cancelled."
            return 0
        fi

        # Decrypt, append, re-encrypt
        local src="$HOME/.local/share/chezmoi/encrypted_dot_zshrc.age"
        local age_key="$HOME/.config/chezmoi/key.txt"
        local recipient=$(grep 'recipient' "$HOME/.config/chezmoi/chezmoi.toml" | sed 's/.*= *"\(.*\)"/\1/')
        local tmpfile=$(mktemp)

        age -d -i "$age_key" "$src" > "$tmpfile" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "Failed to decrypt .zshrc. Check your age key."
            rm -f "$tmpfile"
            return 1
        fi

        echo "export ${key_name}=\"${key_value}\"" >> "$tmpfile"
        age -e -r "$recipient" -o "$src" "$tmpfile" 2>/dev/null
        rm -f "$tmpfile"

        echo ""
        echo "Secret added. Opening .zshrc for review..."
        chezmoi edit "$HOME/$target"

        echo ""
        read "?Press Enter when done reviewing to apply changes (or Ctrl-C to cancel)..."
        echo ""
        echo "Applying changes..."
        chezmoi apply -v
        echo ""
        echo "Done! Run 'exec zsh' to load the new key."
        return 0
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#files[@]} )); then
        target="${files[$choice]}"
        echo ""
        echo "Opening: $target"
    else
        echo "Invalid selection."
        return 1
    fi

    chezmoi edit "$HOME/$target"

    echo ""
    read "?Press Enter when done editing to apply changes (or Ctrl-C to cancel)..."
    echo ""
    echo "Applying changes..."
    chezmoi apply -v
    echo ""
    echo "Done! Changes applied."
}

# Interactive secret lookup -- copies a secret value to clipboard
function chezmoi-secret() {
    local secrets=()
    local names=()
    local i=1

    # Decrypt and parse all export lines from .zshrc
    local src="$HOME/.local/share/chezmoi/encrypted_dot_zshrc.age"
    local age_key="$HOME/.config/chezmoi/key.txt"

    if [[ ! -f "$src" ]]; then
        echo "No encrypted .zshrc found."
        return 1
    fi

    local decrypted
    decrypted=$(age -d -i "$age_key" "$src" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "Failed to decrypt. Check your age key."
        return 1
    fi

    # Also parse encrypted airship.zsh if it exists
    local airship_src="$HOME/.local/share/chezmoi/dot_oh-my-zsh/custom/encrypted_airship.zsh.age"
    if [[ -f "$airship_src" ]]; then
        local airship_decrypted
        airship_decrypted=$(age -d -i "$age_key" "$airship_src" 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            decrypted="$decrypted"$'\n'"$airship_decrypted"
        fi
    fi

    echo "Secrets:"
    echo "─────────────────────────────────"

    while IFS= read -r line; do
        if [[ "$line" =~ ^export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=[\"\']?(.+?)[\"\']?$ ]]; then
            local name="${match[1]}"
            local value="${match[2]}"
            # Strip trailing quote if present
            value="${value%\"}"
            value="${value%\'}"
            names+=("$name")
            secrets+=("$value")
            printf "  %2d) %s\n" "$i" "$name"
            ((i++))
        fi
    done <<< "$decrypted"

    echo "─────────────────────────────────"
    echo "   q) Quit"
    echo ""

    if (( ${#names[@]} == 0 )); then
        echo "No secrets found."
        return 1
    fi

    local choice
    read "choice?Select a secret to copy: "

    if [[ "$choice" == "q" || -z "$choice" ]]; then
        echo "Cancelled."
        return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#secrets[@]} )); then
        echo "Invalid selection."
        return 1
    fi

    echo -n "${secrets[$choice]}" | pbcopy
    echo ""
    echo "Copied ${names[$choice]} to clipboard."
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

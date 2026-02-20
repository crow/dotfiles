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

# Saves clipboard Python code as a callable function
function clipfunc() {
    if [ -z "$1" ]; then
        echo "Usage: clipfunc function_name"
        return 1
    fi
    function_name="$1"
    script_path="$HOME/.oh-my-zsh/custom/${function_name}.py"

    pbpaste > "$script_path"

    if ! python3 -m py_compile "$script_path" 2>/dev/null; then
        echo "Clipboard does not contain valid Python code. Function not created."
        rm "$script_path"
        return 1
    fi

    chmod +x "$script_path"

    eval "function $function_name() {
        python3 '$script_path' \"\$@\"
    }"

    echo "function $function_name() {
    python3 '$script_path' \"\$@\"
}
" >> ~/.oh-my-zsh/custom/dev-tools.zsh

    echo "Function '$function_name' has been created and saved."
    source ~/.oh-my-zsh/custom/dev-tools.zsh
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

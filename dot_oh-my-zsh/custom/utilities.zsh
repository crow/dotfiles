# General utilities

# Refreshes the current shell environment
function refresh() {
    source ~/.zshrc
    exec zsh
}

# Syncs drifted target files back to chezmoi source.
# Use this when an installer (e.g. claude, nvm, brew) has modified a managed
# file directly on disk and you want to capture those changes in chezmoi.
# For the reverse (applying source changes to disk) use: chezmoi apply
function chezmoi-sync() {
    local recipient
    recipient=$(grep 'recipient' "$HOME/.config/chezmoi/chezmoi.toml" | sed 's/.*= *"\(.*\)"/\1/')

    # Parse drifted file paths from chezmoi diff output
    local raw_diff
    raw_diff=$(chezmoi diff --no-pager 2>/dev/null)

    if [[ -z "$raw_diff" ]]; then
        echo "chezmoi: all managed files are in sync."
        return 0
    fi

    local -a drifted_files
    while IFS= read -r line; do
        # Lines look like: diff --git a/.zshrc b/.zshrc
        if [[ "$line" =~ ^'diff --git a/'(.+)' b/' ]]; then
            drifted_files+=("$HOME/${match[1]}")
        fi
    done <<< "$raw_diff"

    if (( ${#drifted_files[@]} == 0 )); then
        echo "chezmoi: all managed files are in sync."
        return 0
    fi

    echo "Drifted files:"
    for f in "${drifted_files[@]}"; do echo "  ${f/$HOME/~}"; done
    echo ""

    local synced=0 failed=0

    for file in "${drifted_files[@]}"; do
        printf "  Syncing %s... " "${file/$HOME/\~}"
        local src
        src=$(chezmoi source-path "$file" 2>/dev/null)

        if [[ "$src" == *.age ]]; then
            # Encrypted file: bypass chezmoi add (which needs TTY) and use age directly
            if age -r "$recipient" -o "$src" "$file" 2>/dev/null; then
                echo "✓ (encrypted)"
                (( synced++ ))
            else
                echo "✗ (encryption failed)"
                (( failed++ ))
            fi
        else
            # Plain file: chezmoi add handles it (autoCommit will fire)
            if chezmoi add "$file" 2>/dev/null; then
                echo "✓"
                (( synced++ ))
            else
                echo "✗"
                (( failed++ ))
            fi
        fi
    done

    echo ""
    if (( synced > 0 )); then
        # Commit any remaining unstaged changes (encrypted files bypassed chezmoi add)
        local repo="$HOME/.local/share/chezmoi"
        if ! git -C "$repo" diff --staged --quiet 2>/dev/null || ! git -C "$repo" diff --quiet 2>/dev/null; then
            git -C "$repo" add -A && \
            git -C "$repo" commit -m "sync: capture drifted managed files" && \
            git -C "$repo" push && \
            echo "Pushed to remote." || echo "Warning: commit/push failed."
        fi
        echo "Synced $synced file(s) to chezmoi."
    fi
    (( failed > 0 )) && echo "Failed to sync $failed file(s)." && return 1
    return 0
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
        echo ""

        # Step 1: key name
        local key_name=""
        read "key_name?Variable name (e.g. OPENAI_API_KEY): "
        if [[ -z "$key_name" ]]; then
            echo "No name provided. Cancelled."
            return 1
        fi
        key_name="${key_name:u}"  # uppercase

        # Step 2: key value
        local key_value=""
        echo ""
        echo "Value source:"
        echo "  1) Paste from clipboard"
        echo "  2) Type it in"
        echo ""
        local value_choice
        read "value_choice?Choose (1/2): "

        if [[ "$value_choice" == "1" ]]; then
            key_value=$(pbpaste 2>/dev/null)
            if [[ -z "$key_value" ]]; then
                echo "Clipboard is empty."
                return 1
            fi
            # If clipboard has KEY=value format, extract just the value
            if [[ "$key_value" =~ ^(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=[\"\']?(.+?)[\"\']?$ ]]; then
                key_value="${match[2]}"
            fi
            echo "Value read from clipboard (${#key_value} chars)."
        elif [[ "$value_choice" == "2" ]]; then
            read "key_value?Value: "
            if [[ -z "$key_value" ]]; then
                echo "No value provided. Cancelled."
                return 1
            fi
        else
            echo "Invalid choice. Cancelled."
            return 1
        fi

        # Step 3: optional expiry
        echo ""
        local expiry=""
        local expiry_choice
        read "expiry_choice?Add expiry date? (y/n): "
        if [[ "$expiry_choice" == "y" ]]; then
            read "expiry?Expiry date (YYYY-MM-DD): "
            if [[ -n "$expiry" ]]; then
                expiry=" | expires: ${expiry}"
            fi
        fi

        # Step 4: confirm
        echo ""
        echo "Will add to .zshrc:"
        echo "  export ${key_name}=\"${key_value:0:20}...\" # added: $(date +%Y-%m-%d)${expiry} | accessed: never"
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

        local today=$(date +%Y-%m-%d)
        echo "export ${key_name}=\"${key_value}\" # added: ${today}${expiry} | accessed: never" >> "$tmpfile"
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
# Updates "accessed:" date in the comment when a secret is copied
function chezmoi-secret() {
    local secrets=()
    local names=()
    local sources=()
    local i=1

    local src="$HOME/.local/share/chezmoi/encrypted_dot_zshrc.age"
    local airship_src="$HOME/.local/share/chezmoi/dot_oh-my-zsh/custom/encrypted_airship.zsh.age"
    local age_key="$HOME/.config/chezmoi/key.txt"
    local recipient=$(grep 'recipient' "$HOME/.config/chezmoi/chezmoi.toml" | sed 's/.*= *"\(.*\)"/\1/')

    if [[ ! -f "$src" ]]; then
        echo "No encrypted .zshrc found."
        return 1
    fi

    local zshrc_decrypted
    zshrc_decrypted=$(age -d -i "$age_key" "$src" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "Failed to decrypt. Check your age key."
        return 1
    fi

    local airship_decrypted=""
    if [[ -f "$airship_src" ]]; then
        airship_decrypted=$(age -d -i "$age_key" "$airship_src" 2>/dev/null)
    fi

    local all_decrypted="$zshrc_decrypted"
    [[ -n "$airship_decrypted" ]] && all_decrypted="$all_decrypted"$'\n'"$airship_decrypted"

    echo "Secrets:"
    echo "─────────────────────────────────"

    while IFS= read -r line; do
        if [[ "$line" =~ ^export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=[\"\']?(.+?)[\"\']?$ ]]; then
            local name="${match[1]}"
            local value="${match[2]}"
            # Strip trailing quote and any comment
            value="${value%\"*}"
            value="${value%\'*}"
            names+=("$name")
            secrets+=("$value")

            # Track which file this came from
            if [[ -n "$airship_decrypted" ]] && echo "$airship_decrypted" | grep -q "^export ${name}="; then
                sources+=("airship")
            else
                sources+=("zshrc")
            fi

            printf "  %2d) %s\n" "$i" "$name"
            ((i++))
        fi
    done <<< "$all_decrypted"

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

    # Update accessed date in the source file
    local selected_name="${names[$choice]}"
    local today=$(date +%Y-%m-%d)
    local target_src="$src"
    local target_decrypted="$zshrc_decrypted"
    if [[ "${sources[$choice]}" == "airship" ]]; then
        target_src="$airship_src"
        target_decrypted="$airship_decrypted"
    fi

    local tmpfile=$(mktemp)
    while IFS= read -r line; do
        if [[ "$line" =~ ^export[[:space:]]+${selected_name}= ]]; then
            if [[ "$line" =~ "# added:" ]]; then
                # Update existing accessed date
                line=$(echo "$line" | sed "s/accessed: [^ ]*/accessed: ${today}/")
            else
                # No tracking comment yet -- add one
                line="${line} # added: unknown | accessed: ${today}"
            fi
        fi
        echo "$line"
    done <<< "$target_decrypted" > "$tmpfile"

    age -e -r "$recipient" -o "$target_src" "$tmpfile" 2>/dev/null
    rm -f "$tmpfile"

    echo ""
    echo "Copied ${selected_name} to clipboard."
}

# Manages which secrets are shared with the bot profile
# Run this on your personal machine to select a subset of secrets for bots/servers
function chezmoi-bot-secrets() {
    local src="$HOME/.local/share/chezmoi/encrypted_dot_zshrc.age"
    local bot_src="$HOME/.local/share/chezmoi/dot_oh-my-zsh/custom/encrypted_bot_secrets.zsh.age"
    local age_key="$HOME/.config/chezmoi/key.txt"
    local recipient=$(grep 'recipient' "$HOME/.config/chezmoi/chezmoi.toml" | sed 's/.*= *"\(.*\)"/\1/')

    local decrypted
    decrypted=$(age -d -i "$age_key" "$src" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "Failed to decrypt .zshrc. Check your age key."
        return 1
    fi

    local -a names lines
    while IFS= read -r line; do
        if [[ "$line" =~ ^export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)= ]]; then
            names+=("${match[1]}")
            lines+=("$line")
        fi
    done <<< "$decrypted"

    if (( ${#names[@]} == 0 )); then
        echo "No secrets found."
        return 1
    fi

    # Load current bot selection
    local -A selected
    if [[ -f "$bot_src" ]]; then
        local bot_decrypted
        bot_decrypted=$(age -d -i "$age_key" "$bot_src" 2>/dev/null)
        while IFS= read -r line; do
            if [[ "$line" =~ ^export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)= ]]; then
                local n="${match[1]}"
                for i in {1..${#names[@]}}; do
                    [[ "${names[$i]}" == "$n" ]] && selected[$i]=1
                done
            fi
        done <<< "$bot_decrypted"
    fi

    _bot_list() {
        echo ""
        echo "Bot profile secrets (✓ = included):"
        echo "─────────────────────────────────"
        for i in {1..${#names[@]}}; do
            local marker=" "
            [[ -n "${selected[$i]}" ]] && marker="✓"
            printf "  [%s] %2d) %s\n" "$marker" "$i" "${names[$i]}"
        done
        echo "─────────────────────────────────"
        echo "  Toggle: enter numbers (space-separated)"
        echo "  a=all  n=none  done=save  q=quit"
    }

    _bot_list
    while true; do
        local input
        read "input?> "
        case "$input" in
            done) break ;;
            q|Q) echo "Cancelled."; unfunction _bot_list; return 0 ;;
            a) for i in {1..${#names[@]}}; do selected[$i]=1; done; _bot_list ;;
            n) selected=(); _bot_list ;;
            *)
                local changed=0
                for token in ${(s: :)input}; do
                    if [[ "$token" =~ ^[0-9]+$ ]] && (( token >= 1 && token <= ${#names[@]} )); then
                        if [[ -n "${selected[$token]}" ]]; then
                            unset "selected[$token]"
                        else
                            selected[$token]=1
                        fi
                        changed=1
                    fi
                done
                (( changed )) && _bot_list
                ;;
        esac
    done

    unfunction _bot_list

    local tmpfile=$(mktemp)
    printf "# Bot profile secrets — managed via chezmoi-bot-secrets\n" > "$tmpfile"
    local count=0
    for i in {1..${#names[@]}}; do
        if [[ -n "${selected[$i]}" ]]; then
            echo "${lines[$i]}" >> "$tmpfile"
            ((count++))
        fi
    done

    age -e -r "$recipient" -o "$bot_src" "$tmpfile" 2>/dev/null
    local rc=$?
    rm -f "$tmpfile"

    if [[ $rc -ne 0 ]]; then
        echo "Failed to encrypt bot secrets."
        return 1
    fi

    echo ""
    echo "$count secret(s) saved to bot profile. Applying..."
    chezmoi apply -v
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

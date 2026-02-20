# Development tools and PATH setup

# Opens chezmoi source directory in Finder
function chezmoidir() { open "$HOME/.local/share/chezmoi"; }

# PATH additions
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="/Applications/PrusaSlicer.app/Contents/MacOS:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/bin/uv:$PATH"
export PATH="$HOME/source/flutter:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PGPT_PROFILES=ollama

# fzf - fuzzy finder (Ctrl+R for history, Ctrl+T for files, Alt+C for cd)
source <(fzf --zsh 2>/dev/null)
export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border=rounded
  --info=inline
  --prompt='> '
  --pointer='▶'
  --marker='✓'
  --color=bg+:#073642,bg:#002b36,spinner:#2aa198,hl:#268bd2
  --color=fg:#839496,header:#268bd2,info:#2aa198,pointer:#2aa198
  --color=marker:#2aa198,fg+:#eee8d5,prompt:#cb4b16,hl+:#268bd2
"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=down:3:wrap"

# Creates a Python venv and installs requirements
function useenv() {
    python3 -m venv .venv
    source .venv/bin/activate
    python3 -m pip install -r requirements.txt
}

# Kills process on port 8081
function kport() {
    lsof -ti:8081 | xargs kill -9
}

# Opens Xcode workspace
function openi() {
    open *.xcworkspace
}

# Opens Android Studio in current directory
function opena() {
    open -a /Applications/Android\ Studio.app .
}

# Purges Xcode DerivedData
function purd() {
    rm -rf ~/Library/Developer/Xcode/DerivedData
}

# Copies all .swift files from a directory to Desktop
copy_swift_files() {
    if [[ -z "$1" ]]; then
        echo "Usage: copy_swift_files <source_directory>"
        return 1
    fi

    local source_dir="$1"

    if [[ ! -d "$source_dir" ]]; then
        echo "Error: Directory '$source_dir' does not exist."
        return 1
    fi

    local parent_folder_name=$(basename "$source_dir")
    local destination_dir="$HOME/Desktop/${parent_folder_name}"
    mkdir -p "$destination_dir"

    find "$source_dir" -type f -name "*.swift" -exec cp -- {} "$destination_dir" \;
    echo "All .swift files have been copied to '$destination_dir'."
}

# Resizes an image into iOS and Android app icon sizes
resize_app_icons() {
    local -a ios_sizes=(20 40 60 29 58 87 40 80 120 76 152 167 1024)
    local -a ios_roles=("iphone" "iphone" "iphone" "iphone" "iphone" "iphone" "ipad" "ipad" "ipad" "ipad" "ipad" "ipad" "ios-marketing")
    local -a ios_scales=("2x" "2x" "3x" "2x" "2x" "3x" "1x" "2x" "3x" "1x" "2x" "2x" "1x")
    local -a android_sizes=("mdpi:48" "hdpi:72" "xhdpi:96" "xxhdpi:144" "xxxhdpi:192")

    local original_image_path="$1"

    if [[ ! -f "$original_image_path" ]]; then
        echo "The file does not exist: $original_image_path"
        return 1
    fi

    if [[ ! -d AppIcons ]]; then
        mkdir AppIcons
    fi

    local ios_iconset_path="AppIcons/AppIcon.appiconset"
    mkdir -p "$ios_iconset_path"

    echo "Starting the resize process for iOS icons..."

    local contents_json="$ios_iconset_path/Contents.json"
    echo '{ "images": [' > "$contents_json"

    for i in "${!ios_sizes[@]}"; do
        local size=${ios_sizes[$i]}
        local role=${ios_roles[$i]}
        local scale=${ios_scales[$i]}
        local scaled_size=$((size * ${scale%x}))
        local filename="icon_${size}x${size}@${scale}.png"

        echo "Resizing to ${scaled_size}x${scaled_size} pixels for $role..."
        convert "$original_image_path" -resize "${scaled_size}x${scaled_size}!" "$ios_iconset_path/$filename"

        jq --arg size "${size}x${size}" --arg scale "$scale" --arg idiom "$role" --arg filename "$filename" \
           '.images += [{"size": ($size), "idiom": $idiom, "filename": $filename, "scale": $scale}]' \
           "$contents_json" > "$contents_json.tmp" && mv "$contents_json.tmp" "$contents_json"
    done

    echo ']}' >> "$contents_json"

    echo "Starting the resize process for Android icons..."

    for entry in "${android_sizes[@]}"; do
        local size_category="${entry%%:*}"
        local size="${entry##*:}"
        local folder="AppIcons/${size_category}"
        mkdir -p "$folder"
        local filename="${size_category}_icon_${size}x${size}.png"

        echo "Resizing to ${size}x${size} pixels for $size_category..."
        convert "$original_image_path" -resize "${size}x${size}!" "$folder/$filename"
    done

    echo "Resizing complete!"
    echo "Resized icons have been saved in the AppIcons directory and AppIcon.appiconset."
    ls -l AppIcons
}

# Finds and replaces AirshipConfig files with local secrets
function applySecrets {
    local source_dir="$HOME/source/davironment"
    local plist_count=0
    local properties_count=0

    echo "Searching for AirshipConfig and airshipconfig.properties files..."

    find . -type f -name 'AirshipConfig.plist.sample' -exec sh -c 'echo "Replacing ${PWD}/${0} with ${1}.plist"; cp "${1}.plist" "${0}"; mv "${0}" "${0%.*}"; ((plist_count+=1))' {} "${source_dir}/AirshipConfig" \;
    find . -type f -name 'AirshipConfig.plist' -exec sh -c 'echo "Updating ${PWD}/${0} with ${1}.plist"; cp "${1}.plist" "${0}"; ((plist_count+=1))' {} "${source_dir}/AirshipConfig" \;

    find . -type f -name 'airshipconfig.properties.sample' -exec sh -c 'echo "Replacing ${PWD}/${0} with ${1}.properties"; cp "${1}.properties" "${0}"; mv "${0}" "${0%.*}"; ((properties_count+=1))' {} "${source_dir}/airshipconfig" \;
    find . -type f -name 'airshipconfig.properties' -exec sh -c 'echo "Updating ${PWD}/${0} with ${1}.properties"; cp "${1}.properties" "${0}"; ((properties_count+=1))' {} "${source_dir}/airshipconfig" \;

    if (( plist_count > 0 || properties_count > 0 )); then
        echo "Replacement and update process complete! ${plist_count} plist and ${properties_count} properties files processed."
    else
        echo "No files were found for replacement."
    fi
}

# Toggles macOS sleep prevention
function adderall() {
    local current=$(pmset -g | grep disablesleep | awk '{print $2}')
    if [[ "$current" == "1" ]]; then
        sudo pmset disablesleep 0
        echo "Sleep re-enabled. Chill mode."
    else
        sudo pmset disablesleep 1
        echo "Sleep disabled. Wired in."
    fi
}

# Adds SSH key to agent
function sshadd { ssh-add --apple-use-keychain ~/.ssh/id_ed25519 }

# Python script wrappers
function pyhello() {
    python3 '$HOME/.oh-my-zsh/custom/pyhello.py' "$@"
}

function pytry() {
    python3 '$HOME/.oh-my-zsh/custom/pytry.py' "$@"
}

function mcolors() {
    python3 '$HOME/.oh-my-zsh/custom/mcolors.py' "$@"
}

function gen_colorsets() {
    python3 '$HOME/.oh-my-zsh/custom/gen_colorsets.py' "$@"
}

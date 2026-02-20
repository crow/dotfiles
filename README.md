# Dotfiles

Managed with [chezmoi](https://chezmoi.io/) + [age](https://github.com/FiloSottile/age) encryption for secrets.

## New Machine Setup

```bash
curl -fsLS https://raw.githubusercontent.com/jdavidcrow/dotfiles/main/bootstrap.sh | bash
```

Or step by step:

```bash
# Install chezmoi + age
sh -c "$(curl -fsLS get.chezmoi.io)"
brew install age

# Initialize from this repo
chezmoi init jdavidcrow --ssh

# Copy your age key to the new machine
# (from password manager, USB drive, etc.)
mkdir -p ~/.config/chezmoi
# paste key into ~/.config/chezmoi/key.txt

# Apply dotfiles (encrypted files are decrypted automatically)
chezmoi apply -v
```

## Structure

| File | Manages |
|---|---|
| `encrypted_dot_zshrc.age` | `~/.zshrc` - shell config with secrets (age-encrypted) |
| `dot_gitconfig.tmpl` | `~/.gitconfig` - git user config |
| `dot_oh-my-zsh/custom/aliases.zsh` | Shell aliases |
| `encrypted_airship.zsh.age` | Airship push functions with secrets (age-encrypted) |
| `dot_oh-my-zsh/custom/git-helpers.zsh` | Git helper functions |
| `dot_oh-my-zsh/custom/dev-tools.zsh` | Dev tools, PATH setup, script wrappers |
| `dot_oh-my-zsh/custom/utilities.zsh` | General utilities, PGP functions |

## Updating

```bash
# Edit a managed file
chezmoi edit ~/.zshrc

# See what would change
chezmoi diff

# Apply changes
chezmoi apply -v

# Commit and push
chezmoi cd
git add -A && git commit -m "update dotfiles" && git push
```

## Secrets

Files containing secrets are age-encrypted in the git repo (`.age` files).
Your age key at `~/.config/chezmoi/key.txt` decrypts them at `chezmoi apply` time.
**Back up your age key** -- without it you cannot decrypt your dotfiles.

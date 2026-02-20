# Dotfiles

Managed with [chezmoi](https://chezmoi.io/) + [LastPass](https://www.lastpass.com/) for secrets.

## New Machine Setup

```bash
curl -fsLS https://raw.githubusercontent.com/jdavidcrow/dotfiles/main/bootstrap.sh | bash
```

Or step by step:

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Initialize from this repo
chezmoi init jdavidcrow --ssh

# Login to LastPass (secrets are fetched at apply time)
lpass login jdavidcrow@gmail.com

# Apply dotfiles
chezmoi apply -v
```

## Structure

| File | Manages |
|---|---|
| `dot_zshrc.tmpl` | `~/.zshrc` - shell config with secrets from LastPass |
| `dot_gitconfig.tmpl` | `~/.gitconfig` - git user config |
| `dot_oh-my-zsh/custom/aliases.zsh` | Shell aliases |
| `dot_oh-my-zsh/custom/airship.zsh.tmpl` | Airship push functions (secrets from LastPass) |
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

All secrets are stored in LastPass under the `Dotfiles/` folder as Secure Notes.
Template files (`.tmpl`) reference them at `chezmoi apply` time -- the git repo never contains plaintext secrets.

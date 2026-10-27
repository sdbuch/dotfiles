# dotfiles

Personal dotfiles for macOS and Linux. Managed via symlinks from a central repo.

## Quick start (macOS)

```bash
git clone git@github.com:sdbuch/dotfiles.git ~/dotfiles
cd ~/dotfiles
./deploy_osx.sh
```

For home-machine extras (personal skills, etc.):

```bash
./deploy_osx.sh --home
```

## What's included

- **Shell**: zsh config (oh-my-zsh, zsh-vi-mode, zsh-autosuggestions)
- **Editor**: neovim (lazy.nvim, treesitter, LSP via Mason, telescope, etc.)
- **Terminal**: WezTerm config, tmux (powerline theme, vim-tmux-navigator)
- **Git**: gitconfig, global gitignore, diff-so-fancy
- **LaTeX**: custom macros, beamer themes, texlab LSP
- **Claude Code**: CLAUDE.md, hooks, skills, agents
- **Python**: ipython config, jupyter config

## Key tools installed via deploy_osx.sh

brew: wget, ripgrep, tmux, gh, keychain, mutagen, rbenv, age
cask: claude, docker, cursor, google-chrome, fonts
other: uv, nvm/node, oh-my-zsh, claude code, tpm

## Local encrypted environment profiles

`scripts/age-env` is a portable macOS/Linux command for local, age-encrypted
environment profiles. The tool is tracked, while profile names, key names,
encrypted values, and the age identity remain outside the repository.

```bash
age-env init
age-env put openai OPENAI_API_KEY
age-env list
age-env has openai OPENAI_API_KEY
age-env doctor openai
age-env run openai -- python my_script.py
```

`put` prompts in an interactive terminal and never accepts values as command
arguments. `run` decrypts in memory, validates the profile against its local
key allowlist, and passes the values only to the child process. There is no
command that prints decrypted values. A child process can still reveal its own
environment, so run only commands that are trusted not to log credentials.

Local state uses the XDG paths below by default:

```text
~/.config/age-env/profiles/<profile>.env.age
~/.config/age-env/profiles/<profile>.keys
~/.local/share/age-env/identity.txt
```

The identity must be mode `0600`. Back up identities and profiles separately
if machine-loss recovery is required; cloning this repository restores only
the tool. `AGE_ENV_CONFIG_DIR`, `AGE_ENV_DATA_DIR`, `AGE_ENV_PROFILE_DIR`, and
`AGE_ENV_IDENTITY` can override the defaults.

## Structure

```
deploy_osx.sh          # macOS setup (symlinks + brew + tools)
deploy_linux.sh        # Linux setup
deploy_common.sh       # Shared helpers (mln symlink function)
init.lua               # Neovim config (symlinked to ~/.config/nvim/init.lua)
.tmux.conf             # Tmux config (powerline + optional local extension)
.gitconfig             # Git config
.zshrc_base_mac        # Base zsh config (sourced from ~/.zshrc)
scripts/               # Portable helper scripts
.claude/               # Claude Code config (hooks, skills, agents)
```

## Notes

- `.gitconfig` may need tweaks on Linux (credential helper)
- `local_config.lua` is gitignored for machine-specific nvim overrides
- Tmux: press `prefix + I` to install TPM plugins after first setup

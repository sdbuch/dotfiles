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

brew: wget, ripgrep, tmux, gh, keychain, mutagen, rbenv
cask: claude, docker, cursor, google-chrome, fonts
other: uv, nvm/node, oh-my-zsh, claude code, tpm

## Remote development (olympus)

For remote development with the olympus repo on a GCP VM, see
[dotfiles-private](https://github.com/sdbuch/dotfiles-private). This sets up:

- **Mutagen** file sync (local editing, remote builds)
- **Remote pyright** LSP over SSH (full type resolution using the remote venv)
- **Tmux statusbar** showing mutagen sync status

Setup order: `deploy_osx.sh` first, then `dotfiles-private/olympus/setup.sh`.

## Structure

```
deploy_osx.sh          # macOS setup (symlinks + brew + tools)
deploy_linux.sh        # Linux setup
deploy_common.sh       # Shared helpers (mln symlink function)
init.lua               # Neovim config (symlinked to ~/.config/nvim/init.lua)
.tmux.conf             # Tmux config (powerline + mutagen status)
.gitconfig             # Git config
.zshrc_base_mac        # Base zsh config (sourced from ~/.zshrc)
scripts/               # Helper scripts (tmux sessions, mutagen status)
.claude/               # Claude Code config (hooks, skills, agents)
```

## Notes

- `.gitconfig` may need tweaks on Linux (credential helper)
- `local_config.lua` is gitignored for machine-specific nvim overrides
- Tmux: press `prefix + I` to install TPM plugins after first setup

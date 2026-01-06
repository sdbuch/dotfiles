#!/bin/bash

# Parse command line arguments
INSTALL_SIXEL=false
INSTALL_MINIMAL=false
for arg in "$@"; do
    case $arg in
        --sixel)
            INSTALL_SIXEL=true
            shift
            ;;
        --minimal)
            INSTALL_MINIMAL=true
            shift
            ;;
    esac
done

source "$(dirname "$0")/deploy_common.sh"

# Ensure ~/.local/bin exists and is in PATH
mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

mkdir -p ~/.vim/{colors,snippets}
mkdir -p ~/scripts
mkdir -p ~/.config/nvim/lua/lualine/themes
mkdir -p ~/.config/nvim/lua/config
mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/skills
mkdir -p ~/.claude/agents

# Config file symlinks
mln "$DOTFILES_DIR/.gitconfig_linux" ~/.gitconfig
mln "$DOTFILES_DIR/.gitignore_global" ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
mln "$DOTFILES_DIR/.vimrc" ~/.vimrc
mln "$DOTFILES_DIR/.aliases" ~/.bash_aliases
mln "$DOTFILES_DIR/.dircolors" ~/.dircolors
mln "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf
mln "$DOTFILES_DIR/.inputrc" ~/.inputrc
mln "$DOTFILES_DIR/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
mln "$DOTFILES_DIR/.claude/settings.json" ~/.claude/settings.json
mln "$DOTFILES_DIR/.claude/hooks/typecheck-python.sh" ~/.claude/hooks/typecheck-python.sh
mln "$DOTFILES_DIR/.claude/hooks/ruff-python.sh" ~/.claude/hooks/ruff-python.sh
mln "$DOTFILES_DIR/.claude/hooks/notify.sh" ~/.claude/hooks/notify.sh
mln "$DOTFILES_DIR/.claude/agents/deslop.md" ~/.claude/agents/deslop.md
mln "$DOTFILES_DIR/.claude/skills/notion-llm-config" ~/.claude/skills/notion-llm-config
mln "$DOTFILES_DIR/.claude/skills/arxiv-html" ~/.claude/skills/arxiv-html

if [ ! -f ~/.zshrc ]; then
    echo ". $DOTFILES_DIR/.zshrc_base_linux" > ~/.zshrc
else
    echo "File exists, not overwriting: ~/.zshrc"
fi

mln "$DOTFILES_DIR/init.lua" ~/.config/nvim/init.lua
mln "$DOTFILES_DIR/latex_highlights.scm" ~/.config/nvim/bundle/nvim-treesitter/queries/latex/highlights.scm
mln "$DOTFILES_DIR/plugins.lua" ~/.config/nvim/lua/plugins.lua
touch "$DOTFILES_DIR/local_config.lua"
mln "$DOTFILES_DIR/local_config.lua" ~/.config/nvim/lua/local_config.lua
mln "$DOTFILES_DIR/lua/config/quarto.lua" ~/.config/nvim/lua/config/quarto.lua
mln "$DOTFILES_DIR/lua/config/molten.lua" ~/.config/nvim/lua/config/molten.lua

if ! grep -q "# DOTFILES_SOURCED" ~/.bashrc 2>/dev/null; then
    echo "# DOTFILES_SOURCED" >> ~/.bashrc
    cat "$DOTFILES_DIR/.bashrc" >> ~/.bashrc
fi

# Vim config
mln "$DOTFILES_DIR/.vim/python_imports.txt" ~/.vim/python_skeleton.py
mln "$DOTFILES_DIR/.vim/colors/wombat256mod.vim" ~/.vim/colors/wombat256mod.vim
mln "$DOTFILES_DIR/.vim/snippets/python.json" ~/.vim/snippets/python.json
mln "$DOTFILES_DIR/scripts/dev-tmux" ~/scripts/dev-tmux
mln "$DOTFILES_DIR/.ipython/profile_default/ipython_config.py" ~/.ipython/profile_default/ipython_config.py

if [ "$INSTALL_MINIMAL" = false ]; then
    # Install zsh locally if not already installed
    if ! command -v zsh &> /dev/null; then
        # we need ncurses-dev for this
        if ! dpkg -l | grep -q libncurses-dev; then
            echo "Installing ncurses-dev (requires sudo)"
            sudo apt-get install -y ncurses-dev
        fi

        # install
        wget https://sourceforge.net/projects/zsh/files/zsh/5.9/zsh-5.9.tar.xz
        tar xf zsh-5.9.tar.xz
        cd zsh-5.9
        ./configure --prefix="$HOME/.local"
        make
        make install
        cd ..
        rm -rf zsh-5.9 zsh-5.9.tar.xz

        # Add local zsh to shells if needed
        echo "$HOME/.local/bin/zsh" >> ~/.shells

        # Update shell startup to use local zsh
        echo '[ -f "$HOME/.local/bin/zsh" ] && exec "$HOME/.local/bin/zsh"' >> ~/.bashrc
    fi

    # Install oh-my-zsh if not present (using local zsh)
    if [ ! -d ~/.oh-my-zsh ]; then
        if [ ! -f ~/zsh_install.sh ]; then
            curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o ~/zsh_install.sh
        fi
        SHELL="$HOME/.local/bin/zsh" ZSH="" sh ~/zsh_install.sh --keep-zshrc --unattended
    fi
fi

# Install Node.js using nvm if not present
if ! command -v node &> /dev/null; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install node
    # Global npm packages (installed to ~/.local)
    npm config set prefix ~/.local
    if [ "$INSTALL_MINIMAL" = true ]; then
        npm install -g tree-sitter-cli
    else
        npm install -g tree-sitter-cli typewritten
    fi
fi

# Install ripgrep locally if not present
if ! command -v rg &> /dev/null; then
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep-13.0.0-x86_64-unknown-linux-musl.tar.gz
    tar xf ripgrep-13.0.0-x86_64-unknown-linux-musl.tar.gz
    cp ripgrep-13.0.0-x86_64-unknown-linux-musl/rg ~/.local/bin/
    rm -rf ripgrep-13.0.0-x86_64-unknown-linux-musl*
fi

if [ "$INSTALL_MINIMAL" = false ]; then
    # Install oh-my-zsh plugins
    if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode ]; then
        git clone https://github.com/jeffreytse/zsh-vi-mode ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode
    fi

    if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
fi

# Install neovim from custom script
chmod +x "$DOTFILES_DIR/install_nvim_linux.sh"
"$DOTFILES_DIR/install_nvim_linux.sh"

# Only install tmux and related packages if --sixel option is provided and --minimal is not
if [ "$INSTALL_SIXEL" = true ] && [ "$INSTALL_MINIMAL" = false ]; then
    chmod +x "$DOTFILES_DIR/install_tmux_ubuntu.sh"
    "$DOTFILES_DIR/install_tmux_ubuntu.sh"
fi

# Install tmux plugin manager if not present
if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

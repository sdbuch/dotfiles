#!/bin/sh
# Setup script for Ubuntu development environment
# Creates necessary symlinks and installs required packages

# Helper for creating directories while symlinking if they don't exist
mln() {
    mkdir -p "$(dirname "$2")" && ln -s "$(realpath "$1")" "$2"
}

cdir=$(pwd)

# Create directory structure for vim/neovim
mkdir -p ~/.vim/{colors,snippets}
mkdir -p ~/scripts
# Neovim directory structure (v0.9.5)
mkdir -p ~/.config/nvim/lua/lualine/themes

# Set up config file symlinks
mln $cdir/.gitconfig_linux ~/.gitconfig
mln $cdir/.gitignore_global ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
mln $cdir/.vimrc ~/.vimrc
mln $cdir/.aliases ~/.aliases
mln $cdir/.dircolors ~/.dircolors
mln $cdir/.tmux.conf ~/.tmux.conf
mln $cdir/.inputrc ~/.inputrc

# Initialize zshrc if it doesn't exist
if [ ! -f ~/.zshrc ]; then
    echo ". $cdir/.zshrc_base_linux" > ~/.zshrc
else
    echo "File exists, not overwriting: ~/.zshrc"
fi

# Neovim configuration symlinks
mln $cdir/init.lua ~/.config/nvim/init.lua
mln $cdir/latex_highlights.scm ~/.config/nvim/bundle/nvim-treesitter/queries/latex/highlights.scm

# Append bashrc contents
cat $cdir/.bashrc >> ~/.bashrc

# Additional config symlinks
mln $cdir/.vim/python_imports.txt ~/.vim/python_skeleton.py
mln $cdir/.ipython/profile_default/ipython_config.py ~/.ipython/profile_term/ipython_config.py
mln $cdir/.vim/colors/wombat256mod.vim ~/.vim/colors/wombat256mod.vim
mln $cdir/.vim/snippets/python.json ~/.vim/snippets/python.json
mln $cdir/scripts/dev-tmux ~/scripts/dev-tmux

# Install zsh and oh-my-zsh if not already installed
if ! command -v zsh &> /dev/null; then
    sudo apt-get install zsh
fi

if [ ! -d ~/.oh-my-zsh ]; then
    if [ ! -f ~/zsh_install.sh ]; then
        curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o ~/zsh_install.sh
    fi
    ZSH="" sh ~/zsh_install.sh --keep-zshrc
    sudo chsh -s $(which zsh) $USER
fi

# Install Node.js if not present
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install nodejs
    # Global npm packages
    sudo npm install -g tree-sitter-cli typewritten
fi

# Install oh-my-zsh plugins
if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode ]; then
    git clone https://github.com/jeffreytse/zsh-vi-mode ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode
fi

if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# Install neovim and tmux from custom scripts
chmod +x $cdir/install_nvim_linux.sh
./install_nvim_linux.sh

chmod +x $cdir/install_tmux_ubuntu.sh
./install_tmux_ubuntu.sh

# Install tmux plugin manager if not present
if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install additional development tools
sudo apt-get install -y ripgrep imagemagick libmagickwand-dev lua5.1 liblua5.1-0-dev universal-ctags

# Install Miniconda if not already installed
if [ ! -d ~/miniconda3 ]; then
    curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh 
    bash Miniconda3-latest-Linux-x86_64.sh -b  # -b flag for batch mode, no user input needed
    ~/miniconda3/bin/conda init zsh
    ~/miniconda3/bin/conda init bash
fi

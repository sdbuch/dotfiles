#!/bin/sh
# Setup script for Ubuntu development environment
# Creates necessary directories and symlinks

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

# Helper for creating directories while symlinking if they don't exist
mln() {
    mkdir -p "$(dirname "$2")" && ln -s "$(realpath "$1")" "$2"
}

cdir=$(pwd)

# Ensure ~/.local/bin exists and is in PATH
mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

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
chmod +x $cdir/install_nvim_linux.sh
./install_nvim_linux.sh

# Only install tmux and related packages if --sixel option is provided and --minimal is not
if [ "$INSTALL_SIXEL" = true ] && [ "$INSTALL_MINIMAL" = false ]; then
    chmod +x $cdir/install_tmux_ubuntu.sh
    ./install_tmux_ubuntu.sh
fi

# Install tmux plugin manager if not present
if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install Miniconda if not already installed
if [ ! -d ~/miniconda3 ]; then
    MINICONDA_SCRIPT="Miniconda3-latest-Linux-x86_64.sh"
    curl -O https://repo.anaconda.com/miniconda/$MINICONDA_SCRIPT
    bash $MINICONDA_SCRIPT -b
    ~/miniconda3/bin/conda init zsh
    ~/miniconda3/bin/conda init bash
    # Clean up the installer script
    rm $MINICONDA_SCRIPT
fi

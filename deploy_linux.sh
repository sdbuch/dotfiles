#!/bin/sh
# copy files for ubuntu into the proper directories.
# (all relative to home directory)
#
# files:
# .bashrc
# .gitconfig_ubuntu
# .gitignore_global
# .tmux.conf
# .vimrc_ubuntu
# .ipython/profile_default/ipython_config.py
# .vim/colors
#
# Download dependencies to ~/github directory too:
# tmux theme:
# - https://github.com/odedlaz/tmux-onedark-theme
# - https://github.com/odedlaz/tmux-status-variables

cdir=$(pwd)

# # clean setup: software
# sudo apt-get install vim-nox
# # or
# sudo add-apt-repository ppa:jonathonf/vim
# sudo apt update && sudo apt install vim
# #
# sudo apt-get install xauth
# sudo apt-get install eog
# sudo apt-get install ctags


# clean setup: dirs
mkdir ~/.vim
mkdir ~/.vim/colors
mkdir ~/.vim/snippets
mkdir ~/scripts
# below for neovim
# For nvim v0.9.5, init file goes at ~/.config/nvim/,
# but plugins go at ~/.local/share/nvim/.
# If overwriting an existing install, might need to clean these directories.
mkdir ~/.config
mkdir ~/.config/nvim
mkdir ~/.config/nvim/lua
mkdir ~/.config/nvim/lua/lualine
mkdir ~/.config/nvim/lua/lualine/themes

# config files
ln -s $cdir/.gitconfig_linux ~/.gitconfig
ln -s $cdir/.gitignore_global ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
ln -s $cdir/.vimrc ~/.vimrc
# TODO: configure to concatenate to existing file like zshrc below...
# ln -s $cdir/.bashrc ~/.bashrc
ln -s $cdir/.aliases ~/.aliases
ln -s $cdir/.dircolors ~/.dircolors
ln -s $cdir/.tmux.conf ~/.tmux.conf
ln -s $cdir/.inputrc ~/.inputrc
if [ ! -f ~/.zshrc ]; then
    touch ~/.zshrc
    echo ". $cdir/.zshrc_base_linux" > ~/.zshrc
else
    echo "File exists, not overwriting: ~/.zshrc"
fi
# cp -n $cdir/.zshrc_base_linux ~/.zshrc  # Copy this file instead, since it'll be modified.

# for neovim
ln -s $cdir/init.lua ~/.config/nvim/init.lua
ln -s $cdir/latex_highlights.scm ~/.config/nvim/bundle/nvim-treesitter/queries/latex/highlights.scm
# ln -s $cdir/plugins.lua ~/.config/nvim/lua/plugins.lua

# cat .bashrc
cat $cdir/.bashrc >> ~/.bashrc

# etc
ln -s $cdir/.vim/python_imports.txt ~/.vim/python_skeleton.py
ln -s $cdir/.ipython/profile_default/ipython_config.py ~/.ipython/profile_default/ipython_config.py
ln -s $cdir/.vim/colors/wombat256mod.vim ~/.vim/colors/wombat256mod.vim
ln -s $cdir/.vim/snippets/python.json ~/.vim/snippets/python.json
ln -s $cdir/scripts/dev-tmux ~/scripts/dev-tmux

# Install zsh...
sudo apt-get install zsh
# Install oh-my-zsh
if [ ! -f ~/zsh-install.sh ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o ~/zsh_install.sh)"
    sh ~/zsh_install.sh --keep-zshrc # --unattended
fi
# Install oh-my-zsh plugins/themes
# typewritten (theme)
sudo npm install -g typewritten
# zsh-vi-mode
git clone https://github.com/jeffreytse/zsh-vi-mode $ZSH_CUSTOM/plugins/zsh-vi-mode
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# try to install nvim
chmod +x $cdir/install_nvim_linux.sh
./install_nvim_linux.sh

# try to install tmux (sixel support!)
chmod +x $cdir/install_tmux_ubuntu.sh
./install_tmux_ubuntu.sh


# install other software
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
sudo apt-get install ripgrep
sudo apt-get install imagemagick
sudo apt-get install libmagickwand-dev

# TODO: install conda
# currently just configure it
~/miniconda3/bin/conda init zsh
~/miniconda3/bin/conda init

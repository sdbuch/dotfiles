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

# clean setup: software
sudo apt-get install vim-nox
sudo apt-get install xauth
sudo apt-get install eog
sudo apt-get install ctags

# clean setup: dirs
mkdir ~/.vim
mkdir ~/.vim/colors
mkdir ~/.vim/snippets
mkdir ~/scripts

# config files
ln -s $cdir/.gitconfig_linux ~/.gitconfig
ln -s $cdir/.gitignore_global ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
ln -s $cdir/.vimrc ~/.vimrc
# ln -s $cdir/.bashrc ~/.bashrc
ln -s $cdir/.bash_aliases ~/.bash_aliases
ln -s $cdir/.dircolors ~/.dircolors
ln -s $cdir/.tmux.conf ~/.tmux.conf

# etc
ln -s $cdir/.vim/python_imports.txt ~/.vim/python_skeleton.py
ln -s $cdir/.vim/colors/wombat256mod.vim ~/.vim/colors/wombat256mod.vim
ln -s $cdir/.vim/snippets/python.json ~/.vim/snippets/python.json
ln -s $cdir/scripts/dev-tmux ~/scripts/dev-tmux



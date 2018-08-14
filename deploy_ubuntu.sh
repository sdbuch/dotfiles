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

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
echo $SCRIPTPATH

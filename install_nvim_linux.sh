#!/bin/bash
#
# borrowed from @brentyi
# use this on ubuntu

if [ ! -f /usr/bin/nvim ]; then
    echo "nvim not found, installing..."
    wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
    sudo chmod +x nvim.appimage
    sudo mv nvim.appimage /usr/bin/nvim
    sudo apt-get install fuse libfuse2
fi

#!/bin/bash

if ! command -v nvim &> /dev/null; then
    echo "nvim not found, installing..."
    wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
    chmod +x nvim.appimage
    mv nvim.appimage ~/.local/bin/nvim

    # Unfortunately we do need sudo for libfuse2
    if ! dpkg -l | grep -q libfuse2; then
        echo "Installing libfuse2 (requires sudo)"
        sudo apt-get install -y libfuse2
    fi
fi

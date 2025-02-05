#!/bin/bash

if ! command -v nvim &> /dev/null; then
    echo "nvim not found, installing..."

    # Create ~/.local/bin if it doesn't exist
    mkdir -p ~/.local/bin

    # Create temporary directory for download
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Download nvim appimage
    wget https://github.com/neovim/neovim/releases/download/v0.10.3/nvim.appimage
    chmod +x nvim.appimage

    # Extract the appimage
    ./nvim.appimage --appimage-extract

    # Remove any existing installation
    rm -rf ~/.local/nvim
    rm -f ~/.local/bin/nvim

    # Move to final location and create symlink
    mv squashfs-root ~/.local/nvim
    ln -s ~/.local/nvim/usr/bin/nvim ~/.local/bin/nvim

    # Cleanup
    cd -
    rm -rf "$TEMP_DIR"

    echo "Neovim installation complete!"
fi

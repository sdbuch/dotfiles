#!/bin/bash

if ! command -v nvim &> /dev/null; then
    echo "nvim not found, installing..."

    mkdir -p ~/.local/bin

    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    wget https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz
    tar xzf nvim-linux-x86_64.tar.gz

    rm -rf ~/.local/nvim
    rm -f ~/.local/bin/nvim
    mv nvim-linux-x86_64 ~/.local/nvim
    ln -s ~/.local/nvim/bin/nvim ~/.local/bin/nvim

    cd -
    rm -rf "$TEMP_DIR"

    echo "Neovim installation complete!"
fi

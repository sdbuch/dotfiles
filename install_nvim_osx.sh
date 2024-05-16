#!/bin/bash
#


if [ ! -f /usr/local/bin/nvim ]; then
    # download
    # wget https://github.com/neovim/neovim/releases/download/nightly/nvim-macos.tar.gz
    wget https://github.com/neovim/neovim/releases/download/stable/nvim-macos-arm64.tar.gz
    xattr -c ./nvim-macos-arm64.tar.gz
    # extract
    tar xzvf nvim-macos-arm64.tar.gz
    # install
    sudo rm -rf /usr/local/nvim
    sudo mv nvim-macos-arm64 /usr/local/nvim
    sudo ln -s /usr/local/nvim/bin/nvim /usr/local/bin/nvim
    # cleanup
    rm -f nvim-macos-arm64.tar.gz
fi

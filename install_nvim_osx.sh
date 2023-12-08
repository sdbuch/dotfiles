#!/bin/bash
#

# download
# wget https://github.com/neovim/neovim/releases/download/nightly/nvim-macos.tar.gz
wget https://github.com/neovim/neovim/releases/download/stable/nvim-macos.tar.gz
xattr -c ./nvim-macos.tar.gz
# extract
tar xzvf nvim-macos.tar.gz
# install
sudo rm -rf /usr/local/nvim
sudo mv nvim-macos /usr/local/nvim
sudo ln -s /usr/local/nvim/bin/nvim /usr/local/bin/nvim
# cleanup
rm -f nvim-macos.tar.gz

# https://github.com/tmux/tmux/wiki/Installing
#

if [ ! -f /usr/local/bin/tmux ]; then
    echo "tmux not found, installing..."
    wget https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz
    sudo chmod +x tmux-3.5a.tar.gz
    tar -zxf tmux-3.5a.tar.gz
    cd tmux-3.5a/
    ./configure --enable-sixel
    make && sudo make install
    rm -rf tmux-3.5a/
    rm -rf tmux-3.5a.tar.gz
fi


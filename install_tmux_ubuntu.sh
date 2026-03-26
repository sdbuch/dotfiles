# https://github.com/tmux/tmux/wiki/Installing
#

if [ ! -f /usr/local/bin/tmux ]; then
    echo "tmux not found, installing..."
    # need some prereqs
    sudo apt-get install -y imagemagick libmagickwand-dev lua5.1 liblua5.1-0-dev libevent-dev bison ncurses-dev build-essential

    wget https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz
    sudo chmod +x tmux-3.5a.tar.gz
    tar -zxf tmux-3.5a.tar.gz
    cd tmux-3.5a/
    ./configure --enable-sixel
    make && sudo make install
    rm -rf tmux-3.5a/
    rm -rf tmux-3.5a.tar.gz
fi


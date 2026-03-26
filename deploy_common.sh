#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mln() {
    local src="$(realpath "$1")"
    local dst="$2"

    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ]; then
        local current="$(readlink "$dst")"
        if [ "$current" = "$src" ]; then
            return 0
        else
            echo "SKIP: $dst exists, points to $current (expected $src)"
            return 1
        fi
    elif [ -e "$dst" ]; then
        echo "SKIP: $dst exists as regular file"
        return 1
    else
        ln -s "$src" "$dst"
        echo "LINK: $dst -> $src"
    fi
}

mln_if_exists() {
    [ -e "$1" ] && mln "$1" "$2"
}

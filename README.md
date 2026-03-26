# dotfiles

Dependencies:

- profile depends
  - keychain (https://www.funtoo.org/Keychain)

- vim plugins 
  - Use vim-plug now, see `.vimrc`

- vim setup
  - tweak paths in .vimrc for python lib locations (comment pythonpath with
    vim-nox? comment final path modification script?)

- using qtconsole across ssh
  - as of jan 2022, better install `jupyter_client v6.1.12` instead of latest

- ls colors
  - solarized lscolors (https://github.com/seebi/dircolors-solarized)

- tmux stuff
  - color theme (https://github.com/odedlaz/tmux-onedark-theme)
  - widgets for the above theme
    (https://github.com/odedlaz/tmux-status-variables)
  - powerline fonts (https://github.com/powerline/fonts)
  - https://github.com/NHDaly/tmux-better-mouse-mode

- pip stuff
  - python linting: mypy, pylint, flake8 (all through pip)

- software to install
  - mosek, MATLAB
  - conda
  - cuda (https://developer.nvidia.com/cuda-downloads)
  - universal-ctags (https://github.com/universal-ctags/ctags)

- scripts directory
  - symlink into `/usr/local/bin/` to get to work

- Notes
  - change .gitconfig if on linux
  - pick one of the .vimrc files if on linux (.vimrc_linux)

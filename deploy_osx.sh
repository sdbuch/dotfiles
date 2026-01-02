#!/bin/bash

source "$(dirname "$0")/deploy_common.sh"

# Create directory structure
mkdir -p ~/.config/nvim/lua/lualine/themes
mkdir -p ~/.config/nvim/snippets
mkdir -p ~/.vim/{colors,snippets}
mkdir -p ~/scripts
mkdir -p ~/.ctags.d
mkdir -p ~/.claude/hooks
mkdir -p ~/.claude/skills
mkdir -p ~/.claude/agents
mkdir -p ~/.cursor

mln "$DOTFILES_DIR/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
mln "$DOTFILES_DIR/.claude/settings.json" ~/.claude/settings.json
mln "$DOTFILES_DIR/.claude/hooks/typecheck-python.sh" ~/.claude/hooks/typecheck-python.sh
mln "$DOTFILES_DIR/.claude/agents/deslop.md" ~/.claude/agents/deslop.md
mln "$DOTFILES_DIR/.cursor/mcp.json" ~/.cursor/mcp.json

# Config files
mln "$DOTFILES_DIR/latex.ctags" ~/.ctags.d/latex.ctags
mln "$DOTFILES_DIR/.gitconfig" ~/.gitconfig
mln "$DOTFILES_DIR/.gitignore_global" ~/.gitignore_global
mln "$DOTFILES_DIR/.latexmkrc" ~/.latexmkrc
mln "$DOTFILES_DIR/.bash_profile" ~/.bash_profile
mln "$DOTFILES_DIR/.aliases" ~/.aliases
mln "$DOTFILES_DIR/.vimrc" ~/.vimrc
mln "$DOTFILES_DIR/.inputrc" ~/.inputrc
mln "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf
mln "$DOTFILES_DIR/.wezterm.lua" ~/.wezterm.lua

if [ ! -f ~/.zshrc ]; then
    echo ". $DOTFILES_DIR/.zshrc_base_mac" > ~/.zshrc
else
    echo "File exists, not overwriting: ~/.zshrc"
fi

mln "$DOTFILES_DIR/sam_macros.def" ~/Library/texmf/tex/latex/local/sam_macros.def
mln "$DOTFILES_DIR/sam_macros_common.def" ~/Library/texmf/tex/latex/local/sam_macros_common.def
mln "$DOTFILES_DIR/sam_macros_nofontspec.def" ~/Library/texmf/tex/latex/local/sam_macros_nofontspec.def
mln "$DOTFILES_DIR/sam_preamble.def" ~/Library/texmf/tex/latex/local/sam_preamble.def
mln "$DOTFILES_DIR/beamercolorthemegemini.sty" ~/Library/texmf/tex/latex/local/beamercolorthemegemini.sty
mln "$DOTFILES_DIR/beamerthemegemini.sty" ~/Library/texmf/tex/latex/local/beamerthemegemini.sty
mln "$DOTFILES_DIR/.vim/python_imports.txt" ~/.vim/python_skeleton.py
mln "$DOTFILES_DIR/.vim/quarto_skeleton.qmd" ~/.vim/quarto_skeleton.qmd
mln "$DOTFILES_DIR/.vim/article_base.txt" ~/.vim/article_base.txt
mln "$DOTFILES_DIR/.vim/beamer_base.txt" ~/.vim/beamer_base.txt
mln "$DOTFILES_DIR/.vim/figure_base.txt" ~/.vim/figure_base.txt
mln "$DOTFILES_DIR/.vim/listings_base.txt" ~/.vim/listings_base.txt
mln "$DOTFILES_DIR/.vim/poster_base.txt" ~/.vim/poster_base.txt
mln "$DOTFILES_DIR/.vim/subfigure_base.txt" ~/.vim/subfigure_base.txt
mln "$DOTFILES_DIR/.vim/tikz_base.txt" ~/.vim/tikz_base.txt
mln "$DOTFILES_DIR/.vim/colors/wombat256mod.vim" ~/.vim/colors/wombat256mod.vim
mln "$DOTFILES_DIR/.vim/snippets/tex.json" ~/.vim/snippets/tex.json
mln "$DOTFILES_DIR/.vim/snippets/python.json" ~/.vim/snippets/python.json
mln "$DOTFILES_DIR/.vim/snippets/tex.json" ~/.config/nvim/snippets/tex.json
mln "$DOTFILES_DIR/.vim/snippets/python.json" ~/.config/nvim/snippets/python.json
mln "$DOTFILES_DIR/init.lua" ~/.config/nvim/init.lua
mln "$DOTFILES_DIR/latex_highlights.scm" ~/.config/nvim/bundle/nvim-treesitter/queries/latex/highlights.scm
mln "$DOTFILES_DIR/plugins.lua" ~/.config/nvim/lua/plugins.lua
touch "$DOTFILES_DIR/local_config.lua"
mln "$DOTFILES_DIR/local_config.lua" ~/.config/nvim/lua/local_config.lua
mln "$DOTFILES_DIR/.jupyter/jupyter_qtconsole_config.py" ~/.jupyter/jupyter_qtconsole_config.py
mln "$DOTFILES_DIR/.ipython/sam_utility.py" ~/.ipython/sam_utility.py
mln "$DOTFILES_DIR/.ipython/profile_default/ipython_config.py" ~/.ipython/profile_default/ipython_config.py
mln "$DOTFILES_DIR/.ipython/profile_default/ipython_kernel_config.py" ~/.ipython/profile_default/ipython_kernel_config.py
cp "$DOTFILES_DIR/keyremap_windowskb.sh" ~/keyremap_windowskb.sh
sudo cp "$DOTFILES_DIR/com.user.keyboardmapping.plist" /Library/LaunchDaemons/com.user.keyboardmapping.plist
git config --global core.excludesfile ~/.gitignore_global

if [ ! -d ~/.oh-my-zsh ]; then
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o ~/zsh_install.sh
    sh ~/zsh_install.sh --keep-zshrc --unattended
fi
# TODO: custom oh-my-zsh plugins

chmod +x "$DOTFILES_DIR/install_nvim_osx.sh"
"$DOTFILES_DIR/install_nvim_osx.sh"

# Tmux plugin manager
if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
mln "$DOTFILES_DIR/scripts/dev-tmux" ~/scripts/dev-tmux

cdir=$(pwd)

# make directories (for neovim)
mkdir ~/.config
mkdir ~/.config/nvim
mkdir ~/.config/nvim/lua
mkdir ~/.config/nvim/pack
mkdir ~/.config/nvim/pack/packer
mkdir ~/.config/nvim/pack/packer/start

# config files
ln -s $cdir/.gitconfig ~/.gitconfig
ln -s $cdir/.gitignore_global ~/.gitignore_global
ln -s $cdir/.latexmkrc ~/.latexmkrc
ln -s $cdir/.profile ~/.profile
ln -s $cdir/.vimrc ~/.vimrc
ln -s $cdir/.inputrc ~/.inputrc
ln -s $cdir/.vim/python_imports.txt ~/.vim/python_skeleton.py

# these directories might need to be adjusted based on
# texmf installation
ln -s $cdir/sam_macros.def ~/Library/texmf/tex/latex/local/sam_macros.def
ln -s $cdir/sam_preamble.def ~/Library/texmf/tex/latex/local/sam_preamble.def
ln -s $cdir/beamercolorthemegemini.sty ~/Library/texmf/tex/latex/local/beamercolorthemegemini.sty
ln -s $cdir/beamerthemegemini.sty ~/Library/texmf/tex/latex/local/beamerthemegemini.sty

# for vim
ln -s $cdir/.vim/article_base.txt ~/.vim/article_base.txt
ln -s $cdir/.vim/beamer_base.txt ~/.vim/beamer_base.txt
ln -s $cdir/.vim/figure_base.txt ~/.vim/figure_base.txt
ln -s $cdir/.vim/listings_base.txt ~/.vim/listings_base.txt
ln -s $cdir/.vim/poster_base.txt ~/.vim/poster_base.txt
ln -s $cdir/.vim/subfigure_base.txt ~/.vim/subfigure_base.txt
ln -s $cdir/.vim/tikz_base.txt ~/.vim/tikz_base.txt
ln -s $cdir/.vim/colors/wombat256mod.vim ~/.vim/colors/wombat256mod.vim
ln -s $cdir/.vim/snippets/tex.json ~/.vim/snippets/tex.json
ln -s $cdir/.vim/snippets/python.json ~/.vim/snippets/python.json

# for neovim
ln -s $cdir/init.vim ~/.config/nvim/init.vim
ln -s $cdir/latex_highlights.scm ~/.config/nvim/bundle/nvim-treesitter/queries/latex/highlights.scm
ln -s $cdir/plugins.lua ~/.config/nvim/lua/plugins.lua

# for ipython / jupyter
ln -s $cdir/.jupyter/jupyter_qtconsole_config.py ~/.jupyter/jupyter_qtconsole_config.py
ln -s $cdir/.ipython/sam_utility.py ~/.ipython/sam_utility.py
ln -s $cdir/.ipython/profile_default/ipython_config.py ~/.ipython/profile_default/ipython_config.py
ln -s $cdir/.ipython/profile_default/ipython_kernel_config.py ~/.ipython/profile_default/ipython_kernel_config.py

# for keyboard remapping
cp $cdir/keyremap_windowskb.sh ~/keyremap_windowskb.sh
sudo cp $cdir/com.user.keyboardmapping.plist /Library/LaunchDaemons/com.user.keyboardmapping.plist

# for gitignore
git config --global core.excludesfile ~/.gitignore_global

#!/bin/bash

# Parse command line arguments
INSTALL_HOME=false
for arg in "$@"; do
    case $arg in
        --home)
            INSTALL_HOME=true
            shift
            ;;
    esac
done

source "$(dirname "$0")/deploy_common.sh"

# Create directory structure
mkdir -p ~/.config/nvim/lua/lualine/themes
mkdir -p ~/.config/nvim/lua/config
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
mln "$DOTFILES_DIR/.claude/statusline-command.sh" ~/.claude/statusline-command.sh
mln "$DOTFILES_DIR/.claude/hooks/typecheck-python.sh" ~/.claude/hooks/typecheck-python.sh
mln "$DOTFILES_DIR/.claude/hooks/ruff-python.sh" ~/.claude/hooks/ruff-python.sh
mln "$DOTFILES_DIR/.claude/hooks/notify.sh" ~/.claude/hooks/notify.sh
mln "$DOTFILES_DIR/.claude/agents/deslop.md" ~/.claude/agents/deslop.md
if [ "$INSTALL_HOME" = true ]; then
    mln "$DOTFILES_DIR/.claude/skills/notion-llm-config" ~/.claude/skills/notion-llm-config
    mln "$DOTFILES_DIR/.claude/skills/arxiv-html" ~/.claude/skills/arxiv-html
    mln "$DOTFILES_DIR/.claude/skills/dblp-reffix" ~/.claude/skills/dblp-reffix
    mln "$DOTFILES_DIR/.claude/skills/scan" ~/.claude/skills/scan
    mln "$DOTFILES_DIR/.claude/skills/gmail" ~/.claude/skills/gmail
    mln "$DOTFILES_DIR/.claude/skills/calendar" ~/.claude/skills/calendar
    mln "$DOTFILES_DIR/.claude/skills/nutrition" ~/.claude/skills/nutrition
fi
mln "$DOTFILES_DIR/.cursor/mcp.json" ~/.cursor/mcp.jsonmkdir -p ~/.config/google-oauth

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
mln "$DOTFILES_DIR/lua/config/quarto.lua" ~/.config/nvim/lua/config/quarto.lua
mln "$DOTFILES_DIR/lua/config/molten.lua" ~/.config/nvim/lua/config/molten.lua
mln "$DOTFILES_DIR/.jupyter/jupyter_qtconsole_config.py" ~/.jupyter/jupyter_qtconsole_config.py
mln "$DOTFILES_DIR/.ipython/sam_utility.py" ~/.ipython/sam_utility.py
mln "$DOTFILES_DIR/.ipython/profile_default/ipython_config.py" ~/.ipython/profile_default/ipython_config.py
mln "$DOTFILES_DIR/.ipython/profile_default/ipython_kernel_config.py" ~/.ipython/profile_default/ipython_kernel_config.py
cp "$DOTFILES_DIR/keyremap_windowskb.sh" ~/keyremap_windowskb.sh
sed "s|/Users/sdbuch|$HOME|g" "$DOTFILES_DIR/com.user.keyboardmapping.plist" | sudo tee /Library/LaunchDaemons/com.user.keyboardmapping.plist > /dev/null
git config --global core.excludesfile ~/.gitignore_global

# Disable mouse acceleration
defaults write .GlobalPreferences com.apple.mouse.scaling -1
defaults write .GlobalPreferences com.apple.trackpad.scaling -1
defaults write NSGlobalDomain com.apple.mouse.linear -bool true

# Rebind Spotlight search to Ctrl+Option+Space (default: Cmd+Space)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>parameters</key><array>
        <integer>32</integer>
        <integer>49</integer>
        <integer>786432</integer>
      </array>
      <key>type</key><string>standard</string>
    </dict>
  </dict>'

# Swap screenshot hotkeys: Cmd+Shift+3/4 → clipboard, Cmd+Ctrl+Shift+3/4 → file
# (default is the opposite)
# Full screenshot to file: Cmd+Ctrl+Shift+3
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 28 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>parameters</key><array>
        <integer>51</integer>
        <integer>20</integer>
        <integer>1441792</integer>
      </array>
      <key>type</key><string>standard</string>
    </dict>
  </dict>'
# Full screenshot to clipboard: Cmd+Shift+3
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 29 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>parameters</key><array>
        <integer>51</integer>
        <integer>20</integer>
        <integer>1179648</integer>
      </array>
      <key>type</key><string>standard</string>
    </dict>
  </dict>'
# Area screenshot to file: Cmd+Ctrl+Shift+4
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 30 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>parameters</key><array>
        <integer>52</integer>
        <integer>21</integer>
        <integer>1441792</integer>
      </array>
      <key>type</key><string>standard</string>
    </dict>
  </dict>'
# Area screenshot to clipboard: Cmd+Shift+4
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 31 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key><dict>
      <key>parameters</key><array>
        <integer>52</integer>
        <integer>21</integer>
        <integer>1179648</integer>
      </array>
      <key>type</key><string>standard</string>
    </dict>
  </dict>'

# Apply symbolic hotkey changes
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Brew packages
brew install wget diff-so-fancy ripgrep tmux rbenv keychain gh terminal-notifier
brew install mutagen-io/mutagen/mutagen
brew install --cask claude docker cursor google-chrome notion linear-linear granola obsidian

# Fonts for WezTerm (skip if already installed)
brew list --cask font-source-code-pro-for-powerline &>/dev/null || brew install --cask font-source-code-pro-for-powerline
brew list --cask font-monaspace &>/dev/null || brew install --cask font-monaspace

# Install uv if not present
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Mac App Store CLI (for Magnet, Strongbox)
if ! command -v mas &> /dev/null; then
    brew install mas
fi
# Magnet (id: 441258766), Strongbox (id: 897283731), Amphetamine (id: 937984704)
mas install 441258766 || echo "Could not install Magnet — may need to be signed into App Store"
mas install 897283731 || echo "Could not install Strongbox — may need to be signed into App Store"
mas install 937984704 || echo "Could not install Amphetamine — may need to be signed into App Store"

if [ ! -d ~/.oh-my-zsh ]; then
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o ~/zsh_install.sh
    sh ~/zsh_install.sh --keep-zshrc --unattended
fi
# Install oh-my-zsh custom plugins
if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode ]; then
    git clone https://github.com/jeffreytse/zsh-vi-mode ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode
fi

if [ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

chmod +x "$DOTFILES_DIR/install_nvim_osx.sh"
"$DOTFILES_DIR/install_nvim_osx.sh"

# Install Node.js using nvm if not present
if ! command -v node &> /dev/null; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install node
fi

# Ensure npm global packages are installed
if command -v npm &> /dev/null; then
    npm list -g tree-sitter-cli &> /dev/null || npm install -g tree-sitter-cli
    npm list -g typewritten &> /dev/null || npm install -g typewritten
fi

# Install Claude Code if not present
if ! command -v claude &> /dev/null; then
    curl -fsSL https://claude.ai/install.sh | sh
fi

# Tmux plugin manager
if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
mln "$DOTFILES_DIR/scripts/dev-tmux" ~/scripts/dev-tmux

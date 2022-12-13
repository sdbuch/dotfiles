# .bashrc

# User specific aliases 
alias cp='cp -i'
alias rm='rm -i'
alias mv='mv -i'
alias ls='ls -G'
alias la='ls -FaG'
alias ll='ls -FlasG'
alias lt='ls -FlasGrt'
alias mex='/Applications/MATLAB.app/bin/mex'
alias rpi='arp -a -n | grep b8:27:eb:'
alias qtconsole='jupyter qtconsole'

#alias vim='vim --servername VIM'
 

# User functions
function cdl() { 
  cd "$@"
  ll
}

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi


# Path specs
export EDITOR=/usr/local/bin/vim
export PATH=${PATH}:/usr/local/lib
export PATH=${PATH}:/opt/homebrew/lib
export PATH=${PATH}:~/projects/github/keychain
export GEM_HOME="$HOME/.gem"

# Lua spec
# This is for a homebrew install as of 8/18/2022...
export LUA_PREFIX="/opt/homebrew/Cellar/lua/5.4.4_1"

# Mypy path for stubs
export MYPYPATH=~/.vim/vim-lsp-settings/stubs

# Start keychain
eval `keychain --eval --agents ssh --inherit any id_ed25519`

#colors
export CLICOLOR=1
#export LSCOLORS='GxFxCxDxBxegedabagaced'
#export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'


test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# History file parameters
HISTSIZ=10000
HISTFILESIZE=200000

# Brew thing
eval "$(/opt/homebrew/bin/brew shellenv)"

# Gstreamer setup...
export GST_PLUGIN_PATH="/opt/homebrew/lib/gstreamer-1.0"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/sdbuch/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/sdbuch/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/sdbuch/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/sdbuch/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# PATH management with anaconda, for brew
export PATHO=$PATH
brew () {
  export PATH="$PATHO"
  # echo "Anaconda removed from path"
  command brew "$@"
  export PATH="/Users/sdbuch/anaconda3/bin:$PATHO"
  # echo "Anaconda restored to path"
}

# config for ruby
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
source /opt/homebrew/opt/chruby/share/chruby/auto.sh
chruby ruby-3.1.2

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/sdbuch/google-cloud-sdk/path.bash.inc' ]; then . '/Users/sdbuch/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/sdbuch/google-cloud-sdk/completion.bash.inc' ]; then . '/Users/sdbuch/google-cloud-sdk/completion.bash.inc'; fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

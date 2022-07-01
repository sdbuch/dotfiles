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

# Start keychain
eval `keychain --eval --agents ssh --inherit any id_ed25519`
 

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
export PATH=${PATH}:~/projects/github/keychain
export GEM_HOME="$HOME/.gem"


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
  echo "Anaconda removed from path"
  command brew "$@"
  export PATH="/Users/sdbuch/anaconda3/bin:$PATHO"
  echo "Anaconda restored to path"
}


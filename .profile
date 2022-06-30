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
export PATH=${PATH}:~/projects/github/keychain
export GEM_HOME="$HOME/.gem"


#colors
export CLICOLOR=1
#export LSCOLORS='GxFxCxDxBxegedabagaced'
#export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'

# PATH management with anaconda, for brew
brew () {
  export PATH="$PATHO"
  echo "Anaconda removed from path"
  command brew "$@"
  export PATH="/Users/sadboys/anaconda3/bin:$PATHO"
  echo "Anaconda restored to path"
}

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# History file parameters
HISTSIZ=10000
HISTFILESIZE=200000


# Following is nonessential
export CLASSPATH=.:/Users/sadboys/algs4/algs4.jar:/Users/sadboys/algs4/stdlib.jar
export PROJECTDIR=.:/Users/sadboys/projects/:/Users/sadboys/algs4/projects
export PATH=${PATH}:/usr/local/opt/go/libexec/bin
export PATH=${PATH}:/usr/texbin
export PATH=${PATH}:/opt/bin
export PATH=${PATH}:~/mosek/mosek/8/tools/platform/osx64x86/bin
export PATH=${PATH}:~/projects/github/math-with-slack
export PATH=${PATH}:/usr/local/sbin/
#export PATH=${PATH}:~/projects/verilog/esn_v/util
#export PATH=${PATH}:/usr/local/lib/python2.7/site-packages/
#export PYTHONPATH=/usr/local/lib/python2.7/site-packages/
#export PYTHONPATH=$PYTHONPATH:~/projects/verilog/esn_v/util

# These are set for interactions with conda + vim (python integration)
# These have bad interactions with other python programs though.
# Good idea to only set them when needed (in vimrc...)
#export PYTHONPATH=$PYTHONPATH:~/anaconda3/bin/python
# export PYTHONHOME=$HOME/anaconda3
# export PYTHONPATH=$HOME/.vim/pack/git-plugins/start/jedi-vim/pythonx/parso

export PATHO=$PATH

# For private exports
if [ -r ~/.not_public ]
then
    source ~/.not_public
fi

# For KDE 4
#export KDEDIRS=$KDEDIRS:$HOME/Library/Preferences/KDE:/usr/local/kde4
#export PATH=/usr/local/kde4/bin:$PATH
#export DYLD_LIBRARY_PATH=/usr/local/kde4/lib:$DYLD_LIBRARY_PATH
#launchctl setenv DYLD_LIBRARY_PATH /usr/local/kde4/lib:$DYLD_LIBRARY_PATH
#export XDG_DATA_HOME=$HOME/Library/Preferences/KDE/share
#export XDG_DATA_DIRS=/usr/local/kde4/share:/usr/local/share:/usr/share


 #Includes for CLANG / G++
if [ -z "$CPATH" ]
then
  export CPATH=/opt/X11/include
else
  export CPATH=$CPATH:/opt/X11/include
fi

if [ -z "$LIBRARY_PATH" ]
then
  export LIBRARY_PATH=/opt/X11/lib
else
  export LIBRARY_PATH=$LIBRARY_PATH:/opt/X11/lib
  export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/lib
fi

if [ -z "$LD_LIBRARY_PATH" ]
then
  export LD_LIBRARY_PATH=/opt/X11/lib
else
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/X11/lib
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
fi

# Start ssh-agent using keychain
eval `keychain --eval --agents ssh --inherit any id_rsa id_rsa_b id_rsa_johnvision`

# added by Anaconda3 2018.12 installer
# >>> conda init >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$(CONDA_REPORT_ERRORS=false '/Users/sadboys/anaconda3/bin/conda' shell.bash hook 2> /dev/null)"
if [ $? -eq 0 ]; then
    \eval "$__conda_setup"
else
    if [ -f "/Users/sadboys/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/sadboys/anaconda3/etc/profile.d/conda.sh"
        CONDA_CHANGEPS1=false conda activate base
    else
        \export PATH="/Users/sadboys/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda init <<<

# Things for CaImAn (Spyder settings)
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/sadboys/Downloads/google-cloud-sdk/path.bash.inc' ]; then . '/Users/sadboys/Downloads/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/sadboys/Downloads/google-cloud-sdk/completion.bash.inc' ]; then . '/Users/sadboys/Downloads/google-cloud-sdk/completion.bash.inc'; fi

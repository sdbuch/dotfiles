# .bashrc

# User specific aliases and functions
alias cp='cp -i'
alias rm='rm -i'
alias mv='mv -i'
alias ls='ls -G'
alias la='ls -FaG'
alias ll='ls -FflasG'
alias lt='ls -FlasGrt'
alias mex='/Applications/MATLAB.app/bin/mex'
#alias vim='vim --servername VIM'

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

export CLASSPATH=.:/Users/sadboys/algs4/algs4.jar:/Users/sadboys/algs4/stdlib.jar
export PROJECTDIR=.:/Users/sadboys/projects/:/Users/sadboys/algs4/projects
export EDITOR=/usr/local/bin/vim
export PATH=$PATH:/usr/local/opt/go/libexec/bin
export PATH=${PATH}:$HOME/gsutil
export PATH=${PATH}:/usr/texbin
export PATH=${PATH}:/usr/local/lib
export PATH=${PATH}:/opt/bin
export PATH=${PATH}:~/mosek/mosek/8/tools/platform/osx64x86/bin
export PATH=${PATH}:~/projects/github/math-with-slack
export PATH=${PATH}:~/projects/github/keychain
#export PATH=${PATH}:~/projects/verilog/esn_v/util
#export PATH=${PATH}:/usr/local/lib/python2.7/site-packages/
#export PYTHONPATH=/usr/local/lib/python2.7/site-packages/
#export PYTHONPATH=$PYTHONPATH:~/projects/verilog/esn_v/util

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

#colors
export CLICOLOR=1
export LSCOLORS='GxFxCxDxBxegedabagaced'
#export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'


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

# History file parameters
HISTSIZ=1000
HISTFILESIZE=2000

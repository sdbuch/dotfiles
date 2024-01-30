## CUSTOM STUFF

# function to fix ssh stuff in tmux after reconnecting
fixssh() {
  eval $(tmux show-env    \
    |sed -n 's/^\(SSH_[^=]*\)=\(.*\)/export \1="\2"/p')
}

# Path adds
export PATH=$PATH:~/scripts
# Vim as default editor
export EDITOR=nvim

# for CUDA
export CUDA_HOME=/usr/local/cuda

# CUDNN library path
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"

# jupyter
alias jupyter-ker="jupyter kernel --KernelManager.connection_file='/home/sam/.jupyter/kernel-config-sam.json'"

# nvim
alias vim='nvim'

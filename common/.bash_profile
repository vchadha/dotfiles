#
# ~/.bash_profile
#

# Source bash env
source $HOME/.bash/env

# Source bash login
source $HOME/.bash/login

# Source bash interactive if interactive shell
if [ "$PS1" ]; then
    source $HOME/.bash/interactive
fi


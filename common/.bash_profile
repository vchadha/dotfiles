#
# ~/.bash_profile
#

# Source bash env
source $HOME/.bash/env

# Set BASH_ENV as empty
BASH_ENV=

# Source bash login
source $HOME/.bash/login

# Source bash interactive if interactive shell
if [ "$PS1" ]; then
    source $HOME/.bash/interactive
fi


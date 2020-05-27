#
# ~/.bash_profile
#

# Source bash env
source ~/.bash/env

# Set BASH_ENV as empty
BASH_ENV=

# Source bash login
source ~/.bash/login

# Source bash interactive if interactive shell
if [ "$PS1" ]; then
    . ~/.bash/interactive
fi

# Old stuff
# [[ -f ~/.bashrc ]] && . ~/.bashrc

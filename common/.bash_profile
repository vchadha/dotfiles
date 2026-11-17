#
# ~/.bash_profile
#

source $HOME/.shell/env

# bash unsets PS1 when it isn't interactive
if [ "$PS1" ]; then
    source $HOME/.bash/interactive
fi

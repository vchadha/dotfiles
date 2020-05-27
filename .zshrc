# If you come from bash you might have to change your $PATH
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to oh-my-zsh installation
ZSH=/usr/share/oh-my-zsh/

# Theme
ZSH_THEME="agnoster"

# Hyphen insensitive completion
HYPHEN_INSENSITIVE="true"

# Command auto-correction
ENABLE_CORRECTION="true"

# Red dots whilst waiting for completion
COMPLETION_WAITING_DOTS="true"

# Plugins
plugins=(
    git
    sudo
    zsh-autosuggestions
)

#
# User configuration
#

# Autosuggestions style
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#4c4c4c"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_HISTORY_IGNORE="cd *"
ZSH_AUTOSUGGEST_COMPLETION_IGNORE="git *"

# Language env
export LANG=en_US.UTF-8

# Preferred editor
export EDITOR='vim'

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# Aliases
source ~/.zsh/interactive

ZSH_CACHE_DIR=$HOME/.cache/oh-my-zsh
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir $ZSH_CACHE_DIR
fi

source $ZSH/oh-my-zsh.sh

# Start up ssh-agent
SSH_ENV="$HOME/.ssh/environment"

function start_agent {
    echo "Initialising new SSH agent..."
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
    echo succeeded
    chmod 600 "${SSH_ENV}"
    . "${SSH_ENV}" > /dev/null
    /usr/bin/ssh-add;
}

# Source SSH settings, if applicable

if [ -f "${SSH_ENV}" ]; then
    . "${SSH_ENV}" > /dev/null
    ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
        start_agent;
    }
else
     start_agent;
fi


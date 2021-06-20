#
# ZSH Configuration File
#

#
# Global
#

# Create a hash table for globally stashing variables
typeset -A __GVARS

__GVARS[ITALIC_ON]=$'\e[3m'
__GVARS[ITALIC_OFF]=$'\e[23m'
__GVARS[VCS_COLOR]='green'

#
# ZSH Options
#

# Case insensitive globbing
setopt NO_CASE_GLOB

# No auto cd
setopt NO_AUTO_CD

# Tab completing directory appends a slash
setopt AUTO_PARAM_SLASH

# Shared history file
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# No duplicates in history
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE

# Verify history replacement
setopt HIST_VERIFY

# Always move cursor to end
setopt ALWAYS_TO_END

# Auto push last cd to stack
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_MINUS

# Don't print dir stack after push/pop
setopt PUSHD_SILENT

# Disable flow control with start and stop characters
setopt NO_FLOW_CONTROL

# Allow comments in interactive mode
setopt INTERACTIVE_COMMENTS

# Substitution uses prompts
setopt PROMPT_SUBST

# Auto-insert first possible completion
setopt MENU_COMPLETE

# Make completion lists densely packed
setopt LIST_PACKED

# Unmatched patterns are left unchanged
setopt NO_NOMATCH

# Alow prompt substitution
setopt PROMPT_SUBST

# History file settings
HISTFILE=$HOME/.zsh_history

SAVEHIST=5000
HISTSIZE=2000

#
# Prompt
#

# Git integration
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes false
zstyle ':vcs_info:*' use-simple

zstyle ':vcs_info:git+set-message:*' hooks git-dirty
zstyle ':vcs_info:git*:*' formats '%F{$__GVARS[VCS_COLOR]}[%b%m%c%u]%f'
zstyle ':vcs_info:git*:*' actionformats '%F{$__GVARS[VCS_COLOR]}[%b|%a%m%c%u]%f'

# Right side prompt with timing, git info and full path
_RPROMPT="\${vcs_info_msg_0_} %F{blue}%~%f"

# Set prompt based on number of nested shells
# Anonymous function to avoid leaking variables.
function () {
    local LVL=$SHLVL

    # Check for TMUX
    if [ "$TERM" = "tmux-256color" ] && [ -n "$TMUX" ]; then
        local LVL=$(($SHLVL - 1))
    fi
    
    local SUFFIX='%(!.%F{yellow}%n%f .)%(!.%F{yellow}.%F{red})'$(printf '\u276f%.0s' {1..$LVL})'%f'

    PROMPT="%(?..%F{yellow}!%f)%B%F{blue}%1~%f%b%  $SUFFIX "
    RPROMPT="$_RPROMPT"
}

#
# Plugins
#

source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#abb2ba"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_HISTORY_IGNORE="cd *"
ZSH_AUTOSUGGEST_COMPLETION_IGNORE="git *"

source ~/.zsh/plugins/sudo/sudo.plugin.zsh

#
# User configuration
#

#
# Bindings
#

bindkey '^[[A' up-line-or-search # up arrow
bindkey '^[[B' down-line-or-search # down arrow

# Language env
export LANG=en_US.UTF-8

# Preferred editor
export EDITOR='vim'

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# Tab completion
autoload -Uz compinit && compinit

# Make completion:
# - Try exact (case-sensitive) match first.
# - Then fall back to case-insensitive.
# - Accept abbreviations after . or _ or - (ie. f.b -> foo.bar).
# - Substring complete (ie. bar -> foobar).
zstyle ':completion:*' matcher-list '' '+m:{[:lower:]}={[:upper:]}' '+m:{[:upper:]}={[:lower:]}' '+m:{_-}={-_}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Colorize completions using default `ls` colors.
zstyle ':completion:*' list-colors ''

# Allow completion of ..<Tab> to ../ and beyond.
zstyle -e ':completion:*' special-dirs '[[ $PREFIX = (../)#(..) ]] && reply=(..)'

# $CDPATH is overpowered (can allow us to jump to 100s of directories) so tends
# to dominate completion; exclude path-directories from the tag-order so that
# they will only be used as a fallback if no completions are found.
zstyle ':completion:*:complete:(cd|pushd):*' tag-order 'local-directories named-directories'

# Categorize completion suggestions with headings:
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format %F{default}%B%{$__GVARS[ITALIC_ON]%}--- %d ---%{$__GVARS[ITALIC_OFF]%}%b%f

# Enable keyboard navigation of completions in menu
# (not just tab/shift-tab but cursor keys as well):
zstyle ':completion:*' menu select

#
# Hooks
#
autoload -U add-zsh-hook

function +vi-git-dirty() {
    emulate -L zsh
    local ref="$vcs_info_msg_0_"
    
    if [[ -n "$ref" ]]; then
        if [[ -n "$(git status --porcelain --ignore-submodules)" ]]; then
            __GVARS[VCS_COLOR]='yellow'
        else
            __GVARS[VCS_COLOR]='green'
        fi
    fi
}

typeset -F SECONDS
function -record-start-time() {
    emulate -L zsh

    ZSH_START_TIME=${ZSH_START_TIME:-$SECONDS}
}
add-zsh-hook preexec -record-start-time

function -report-start-time() {
    emulate -L zsh

    if [ $ZSH_START_TIME ]; then
        local DELTA=$(($SECONDS - $ZSH_START_TIME))
        local DAYS=$((~~($DELTA / 86400)))
        local HOURS=$((~~(($DELTA - $DAYS * 86400) / 3600)))
        local MINUTES=$((~~(($DELTA - $DAYS * 86400 - $HOURS * 3600) / 60)))
        local SECS=$(($DELTA - $DAYS * 86400 - $HOURS * 3600 - $MINUTES * 60))
        local ELAPSED=''
        
        test "$DAYS" != '0' && ELAPSED="${DAYS}d"
        test "$HOURS" != '0' && ELAPSED="${ELAPSED}${HOURS}h"
        test "$MINUTES" != '0' && ELAPSED="${ELAPSED}${MINUTES}m"
    
        if [ "$ELAPSED" = '' ]; then
            SECS="$(print -f "%.2f" $SECS)s"
        elif [ "$DAYS" != '0' ]; then
            SECS=''
        else
            SECS="$((~~$SECS))s"
        fi
        
        ELAPSED="${ELAPSED}${SECS}"
        RPROMPT="%F{cyan}%{$__GVARS[ITALIC_ON]%}$ELAPSED%{$__GVARS[ITALIC_OFF]%}%f $_RPROMPT"
        unset ZSH_START_TIME
    else
        RPROMPT="$_RPROMPT"
    fi
}
add-zsh-hook precmd -report-start-time

# Remember each command we run
function -record-command() {
    __GVARS[LAST_COMMAND]="$2"
}
add-zsh-hook preexec -record-command

# Update vcs_info (slow) after any command that probably changed it
function -maybe-show-vcs-info() {
    local LAST="$__GVARS[LAST_COMMAND]"

    # In case user just hit enter, overwrite LAST_COMMAND, because preexec
    # won't run and it will otherwise linger.
    __GVARS[LAST_COMMAND]="<unset>"

    # Check first word; via:
    # http://tim.vanwerkhoven.org/post/2012/10/28/ZSH/Bash-string-manipulation
    case "$LAST[(w)1]" in
        cd|cp|git|rm|touch|mv|vim)
        vcs_info
        ;;
        *)
        ;;
    esac
}
add-zsh-hook precmd -maybe-show-vcs-info

# Aliases and others
source $HOME/.zsh/interactive

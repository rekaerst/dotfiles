#
# History
#

# Remove older command from the history if a duplicate is to be added.
setopt hist_ignore_all_dups

# disable confirmation of history expansions
unsetopt hist_verify

#
# Input/output
#

# Set editor default keymap to emacs (`-e`) or vi (`-v`)
bindkey -v

# Prompt for spelling correction of commands.
setopt correct

# Customize spelling correction prompt.
SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f [nyae]? '

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# vi keybinding timeout
KEYTIMEOUT=25

# Set tab width to size of 4 spaces
tabs -4

#
# MISC
#

# pager
env_default 'PAGER' 'less'
env_default 'LESS' '-R'


# recognize comments
setopt interactivecomments
# auto correct commands
setopt correct
# allow overwrite redirect
setopt clobber
# check jobs
setopt checkjobs

autoload -Uz is-at-least

# *-magic is known buggy in some versions; disable if so
if [[ $DISABLE_MAGIC_FUNCTIONS != true ]]; then
	for d in $fpath; do
		if [[ -e "$d/url-quote-magic" ]]; then
			autoload -Uz bracketed-paste-magic
			zle -N bracketed-paste bracketed-paste-magic
			autoload -Uz url-quote-magic
			zle -N self-insert url-quote-magic
			break
		fi
	done
fi

## jobs
setopt long_list_jobs

env_default 'PAGER' 'less'
env_default 'LESS' '-R'

## super user alias
alias _='sudo '

# recognize comments
setopt interactivecomments
# auto correct commands
setopt correct

# ls colors
autoload -U colors && colors

ls --color -d . &>/dev/null && alias ls='ls --color=tty' || { ls -G . &>/dev/null && alias ls='ls -G' }

eval $(dircolors "$XDG_CONFIG_HOME"/dircolors)

# Take advantage of $LS_COLORS for completion as well.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# enable diff color if possible.
if command diff --color . . &>/dev/null; then
	alias diff='diff --color'
fi

setopt auto_cd
setopt multios
setopt prompt_subst

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=243"

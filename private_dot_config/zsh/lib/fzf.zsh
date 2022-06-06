# Use fd (https://github.com/sharkdp/fd) instead of the default find

#######################################
# fzf options
#######################################

export FZF_DEFAULT_OPTS="\
	--bind 'ctrl-u:preview-page-up'
	--bind 'ctrl-d:preview-page-down'
	--bind 'ctrl-b:page-up'
	--bind 'ctrl-f:page-down'
	--bind 'alt-b:backward-char'
	--bind 'alt-f:forward-char'
	--ansi
"

#######################################
# shell integration
#######################################

_fzf_compgen_path() {
  command fd --hidden --follow --exclude ".git" . "$1"
}
_fzf_compgen_dir() {
  command fd --type d --hidden --follow --exclude ".git" . "$1"
}

fzf_bindkey() {
	if [[ -d /usr/share/fzf ]]; then
		source /usr/share/fzf/completion.zsh
		source /usr/share/fzf/key-bindings.zsh 
		bindkey -M emacs '\ed' fzf-cd-widget
		bindkey -M vicmd '\ed' fzf-cd-widget
		bindkey -M viins '\ed' fzf-cd-widget
		fzf_zsh_help() {
			echo "\e[33;1mC-t\e[0m list files+folders in current directory, (e.g., type \e[34mgit add\e[0m , press \e[33;1mC-t\e[0m, select a few files using \e[33;1mTab\e[0m, finally \e[33;1mEnter\e[0m)"
			echo "\e[33;1mC-r\e[0m search history of shell commands"
			echo "\e[33;1mM-c\e[0m fuzzy change directory"
		}
	fi
}

#######################################
# fzf-tab
#######################################
fzf_tab_config() {
	# disable sort when completing `git checkout`
	zstyle ':completion:*:git-checkout:*' sort false
	# set descriptions format to enable group support
	zstyle ':completion:*:descriptions' format '[%d]'
	# manual page completion
	zstyle ':completion:*:manuals' separate-sections true
	zstyle ':completion:*:manuals.(^1*)' insert-sections true
	# enable group
	zstyle ':completion:*' group-name ''
	# enable tmux popup in tmux session
	if [[ -n "$TMUX" ]]; then
		zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
		zstyle ':fzf-tab:*' popup-pad 50 0
		zstyle ':fzf-tab:*:options' popup-pad 0 0
	fi
	
	#
	# preview
	#
	
	# generic
	zstyle ':fzf-tab:complete:*:*' fzf-preview \
		'if [[ "$group" == "[file]" ]] || [[ "$group" == "[files]" ]]; then
			prv ${(Q)realpath} $FZF_PREVIEW_COLUMNS $FZF_PREVIEW_LINES 2>/dev/null
		else
			echo $group
		fi'
	# disable preview for command options and subcommands	
	zstyle ':fzf-tab:complete:*:options' fzf-preview 
	zstyle ':fzf-tab:complete:*:argument-1' fzf-preview

	# pacman
	zstyle ':fzf-tab:complete:pacman:*' fzf-preview \
		'localf=(/var/lib/pacman/local/${word}*(N))
		if [[ -n "${localf[1]}" ]]; then
			echo "\033[36;1m[installed]\033[0m"
			COLUMNS=$FZF_PREVIEW_COLUMNS pacman --color=always -Qi $word 
		else
			COLUMNS=$FZF_PREVIEW_COLUMNS pacman --color=always -Si $word
		fi
		'

	# command
	zstyle ':fzf-tab:complete:-command-:*' fzf-preview \
	  '(out=$(MANWIDTH=$FZF_PREVIEW_COLUMNS man "$word") 2>/dev/null && echo $out) \
	  || (out=$(which "$word") && echo $out) || echo "${(P)word}"'

	# directory's content with ls when completing cd
	zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'

	# systemd unit status
	zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

	# environment variable
	zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
	fzf-preview 'echo ${(P)word}'

	# git
	zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
		'git diff $word | delta'
	zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
		'git log --color=always $word'
	zstyle ':fzf-tab:complete:git-help:*' fzf-preview \
		'git help $word | bat -plman --color=always'
	zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
		'case "$group" in
		"commit tag") git show --color=always $word ;;
	*) git show --color=always $word | delta ;;
		esac'
	zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
		'case "$group" in
		"modified file") git diff $word | delta ;;
		"recent commit object name") git show --color=always $word | delta ;;
		*) git log --color=always $word ;;
		esac'
	zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview 'MANWIDTH=$FZF_PREVIEW_COLUMNS man $word'
}

fzf_bindkey
fzf_tab_config

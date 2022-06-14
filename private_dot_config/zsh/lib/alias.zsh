#!/bin/zsh

# use proxy for httping
alias httping="httping -E"
# use proxy for ssh
if [[ -n "$all_proxy" ]]; then
	alias ssh="ssh -o 'ProxyCommand ncat --proxy-type socks5 --proxy $(echo $all_proxy | cut -d'/' -f3)  %h %p'"
fi
alias ssh="ssh -o 'ProxyCommand ncat --proxy-type socks5 --proxy 127.0.0.1:1080  %h %p'"
# use sudo for alias
alias sudo='sudo '
# task
alias taskui="taskwarrior-tui"
# dotfiles
if (($+commands[chezmoi])); then
	alias dflg="lazygit -p $(chezmoi source-path)"
	alias dotfiles="cd $(chezmoi source-path)"
fi
# git
alias lg="lazygit"
# use exa as ls
if (($+commands[exa])) then
	alias ls="exa"
	alias ll="exa -l"
	alias l="exa -la"
fi
# trash command
if (($+commands[trash])) then
	alias th="trash"
	alias thc="trash-empty"
elif (($+commands[gio])) then 
	alias th="gio trash"
	alias thc="gio trash --empty"
fi
# misc
alias help=run-help
alias html2pdf='wkhtmltopdf'
alias info='info --vi-keys'
alias rename=perl-rename
alias hs="python -m http.server"
alias locate='locate --regex'
alias R="R --quiet"
alias jitrocks="luarocks --lua-version 5.1"
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'
bamd() {brightnessctl -d 'amdgpu*' s "${1}%"}
prv() {
	local output=$(command prv $@) 
	local lines=$(echo $output | wc -l)
	if (( lines > $(tput lines) - 2 )); then
		echo $output | less
	else
		echo $output
	fi
}

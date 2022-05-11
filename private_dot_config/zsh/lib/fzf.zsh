# Use fd (https://github.com/sharkdp/fd) instead of the default find
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

if [[ -d /usr/share/fzf ]]; then
	source /usr/share/fzf/completion.zsh
	source /usr/share/fzf/key-bindings.zsh 
	fzf_zsh_help() {
		echo "\e[33;1mC-t\e[0m list files+folders in current directory, (e.g., type \e[34mgit add\e[0m , press \e[33;1mC-t\e[0m, select a few files using \e[33;1mTab\e[0m, finally \e[33;1mEnter\e[0m)"
		echo "\e[33;1mC-r\e[0m search history of shell commands"
		echo "\e[33;1mM-c\e[0m fuzzy change directory"
	}
fi


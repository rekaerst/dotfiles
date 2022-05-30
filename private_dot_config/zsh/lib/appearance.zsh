# ls colors
autoload -U colors && colors

ls --color -d . &>/dev/null && alias ls='ls --color=tty' || { ls -G . &>/dev/null && alias ls='ls -G' }

if [[ -f "$XDG_CONFIG_HOME/dircolors" ]]; then
	eval $(dircolors "$XDG_CONFIG_HOME"/dircolors)
fi
# Take advantage of $LS_COLORS for completion as well.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# enable applications color
alias diff='diff --color'

# coloriser

if [[ -n "$TERM" ]] && [[ ! "$TERM" == "dumb" ]] && (( $+commands[grc] )); then
	cmds=(
		blkid
		configure
		cvs
		df
		dig
		du
		env
		fdisk
		findmnt
		free
		getfacl
		id
		ip
		iptables
		iwconfig
		last
		lsattr
		lsblk
		lsmod
		lsof
		lspci
		mount
		netstat
		nmap
		ping
		ping6
		ps
		sar
		sensors
		ss
		stat
		sysctl
		tcpdump
		ulimit
		uptime
		vmstat
		whois
	)
	for cmd in $cmds ; do
		if (( $+commands[$cmd] )) ; then
			# $cmd() {
			# 	grc --colour=auto ${commands[$0]} "$@"
			# }
			
			alias $cmd="grc $cmd"
		fi
	done
	unset cmd cmds
fi


export GREP_COLORS="mt=31;1"
export CHTSH_QUERY_OPTIONS="style=paraiso-dark"

setopt multios
setopt prompt_subst

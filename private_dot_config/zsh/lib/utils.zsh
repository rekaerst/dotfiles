#
# Show most used command
zsh_stats() {
	fc -l 1 \
		| awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' \
		| grep -v "./" | sort -nr | head -40 | column -c3 -s " " -t | nl
}

##################################################################
# Set variable "$1" to default value "$2" if "$1" is not yet defined.
#
# Arguments:
#    1. name - The variable to set
#    2. val  - The default value
# Return value:
#    0 if the variable exists, 3 if it was set
##################################################################
default() {
	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2"   && return 3
}


# Print error message
err() {
	echo >&2 -e "\e[31;1m$*\e[0m"
}

##################################################################
# Set environment variable "$1" to default value "$2" if "$1" is not yet defined.
#
# Arguments:
#    1. name - The env variable to set
#    2. val  - The default value
# Return value:
#    0 if the env variable exists, 3 if it was set
##################################################################
env_default() {
	[[ ${parameters[$1]} = *-export* ]] && return 0
	export "$1=$2" && return 3
}

#
# Proxy
#

##################################################################
# Manage proxy settings
##################################################################
proxyctl() {
	usage() {
		echo "\

Usage:
  proxyctl COMMAND [arguments]

Commands:
  on		- turn on proxy
  off		- turn off proxy
  status	- show status
  help		- show help

Arguments:
-s server		specific server to use (default to http://127.0.0.1:3128)
-e				change desktop environment proxy settings
-g				change git ssh socks proxy, optionally specific address,
-a server		specific socks proxy address (default to 127.0.0.1:1080)
"
	}
	export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com,192.168.0.0/16"

	local proxy_env=(http_proxy https_proxy HTTP_PROXY HTTPS_PROXY rsync_proxy RSYNC_PROXY)
	local server_url="http://127.0.0.1:3128"
	local socks_address="127.0.0.1:1080"
	local de_flag=0 git_flag=0
	local cmd=
	local url_regex='(https?|socks([0-9]))://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
	local addr_regex='^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))(:([0-9])+)?$'
	
	# parsing
	if (($# == 0)); then
		echo "$0: no command was specified"
		usage
		return
	fi

	case "$1" in
	on)
		cmd="on"
		shift
		;;
	off)
		cmd="off"
		shift
		;;
	status)
		cmd="status"
		shift
		;;
	help)
		usage
		return
		;;
	*)
		err "Invalid command $1."
		usage
		return 1
		;;
	esac

	while getopts ":s:ega:" opt; do
		case "$opt" in
		s)
			server_url="$OPTARG"
			;;
		e)
			de_flag=1
			;;
		g)
			git_flag=1
			;;
		a)
			socks_address="$OPTARG"
			;;
		:)
			err "option requires an argument."
			usage
			return 1
			;;
		?) 
			err "Invalid command option."
			usage
			return 1
			;;
		esac
	done

	# valid url and address
	if [[ ! "$server_url" =~ "$url_regex" ]] || [[ ! "$socks_address" =~ "$addr_regex" ]]; then
		err "Invalid server url or address"
		return 1
	fi
	
	# extract host and port
	local host="$(echo $server_url | awk -F'[/:]' '{print $4}')"
	local port="$(echo $server_url | awk -F':' '{print $3}')"
	[[ -z "$port" ]] && port=22
	local socks_host=$(echo $socks_address | awk -F':' '{print $1}')
	local socks_port=$(echo $socks_address | awk -F':' '{print $2}')
	[[ -z "$socks_port" ]] && socks_port=1080

	case "$cmd" in 
	on)
		for envar in "${proxy_env[@]}"; do
			export $envar=$server_url
		done
		all_proxy="socks://$socks_address"
		ALL_PROXY="socks://$socks_address"
		# git
		if ((git_flag == 1)); then
			export ssh_proxy="ProxyCommand ncat --proxy-type socks5 --proxy $socks_address  %h %p"
			git config -f $XDG_CACHE_HOME/git_proxy core.sshCommand "ssh -o '$ssh_proxy'"
		fi
		# desktop environment
		if ((de_flag == 1)); then
			if [[ -f /usr/bin/gsettings ]]; then
				gsettings set org.gnome.system.proxy mode 'manual'
				gsettings set org.gnome.system.proxy.http host "$host"
				gsettings set org.gnome.system.proxy.http port "$port"
				gsettings set org.gnome.system.proxy.ftp host "$host"
				gsettings set org.gnome.system.proxy.ftp port "$port"
				gsettings set org.gnome.system.proxy.https host "$host"
				gsettings set org.gnome.system.proxy.https port "$port"
				gsettings set org.gnome.system.proxy.socks host "$socks_host" 
				gsettings set org.gnome.system.proxy.socks port "$socks_port"
				gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '10.0.0.0/8', '192.168.0.0/16', '172.16.0.0/12' , '*.localdomain.com' ]"
			fi
		fi
		;;
	off)
		unset "${proxy_env[@]}"
		unset all_proxy ALL_PROXY
		#git
		if ((git_flag == 1)); then
			git config -f $XDG_CACHE_HOME/git_proxy --unset core.sshCommand 
		fi
		# desktop environment
		if ((de_flag == 1)); then
			if [[ -f /usr/bin/gsettings ]]; then
				gsettings set org.gnome.system.proxy mode 'none'
			fi
		fi
		;;
	status)
		if [[ ! -z "$http_proxy" ]]; then
			echo "proxy environment variable is set to $http_proxy"
		fi
		#git
		local ssh_cmd=$(git config -f /home/arthur/.cache/git_proxy --get core.sshCommand)
		if [[ ! -z "$ssh_cmd" ]]; then
			echo "git ssh proxy is set to $(echo $ssh_cmd | sed -n 's/.*proxy //p;' | sed 's/ .*//g')"
		fi
		# desktop environment
		if [[ -f /usr/bin/gsettings ]]; then
			if [[ "$(gsettings get org.gnome.system.proxy mode)" != "'none'" ]]; then
				echo "gnome proxy enabled"
			fi
		fi
		;;
	esac
}

#
# Python
#

##################################################################
# Update all python packages
# Arguments:
#	None
##################################################################
pip_update() {
	local requirements="$HOME/.local/lib/requirements.txt"
	if [[ -f $requirements ]]; then
		pip install -r $requirements -U
	else
		err "file $requirements not found"
	fi
}


#
# Pacman
#

##################################################################
# list package by size
# Arguments:
#	None
##################################################################
pacsize() {
	pacman -Qi | awk '/^Name/{name=$3} /^Installed Size/{print $4$5, name}' | sort -h
}

##################################################################
# list files in package by size
# Arguments:
#	1. package
##################################################################
pacblame() {
	if [[ -z $1 ]]; then
		echo "list files in package by size"
		echo "Usage: pacblame package"
		return 1
	fi
	pacman -Qlq $1 | grep -v '/$' | xargs -r du -h | sort -h
}


#
# git
#

##################################################################
# pull all repositories under current folder 
# Arguments:
#	1. package
##################################################################
 pullall() {
	ls | xargs -P100 -I{} git -C {} pull
}

##################################################################
# Get size of github repo
# Arguments:
#	1. repositorie
##################################################################
reposize() {
	[[ -z $1 ]] && echo "Usage: $0 owner/reponame" && return 1
	curl -s https://api.github.com/repos/$1 | jq '.size' | numfmt --to=iec --from-unit=1024
}

#
# Graphics
#

##################################################################
# Make programs use nvidia gpu
# Arguments:
#	None
##################################################################
nvidia() {
	export __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json 
}

##################################################################
# Do not use nvidia GPU
# Arguments:
#	None
##################################################################
nonvidia() {
	unset __NV_PRIME_RENDER_OFFLOAD __GLX_VENDOR_LIBRARY_NAME __VK_LAYER_NV_optimus VK_ICD_FILENAMES
	export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
}


#
# qemu
#

# qemu wrapper
qemu() {
	# set hugepages
	local memsize pages

	if [[ "$@" == *"hugepages"* ]]; then
		memsize=$(echo $@ | grep -oP "\-m\s+\K\w+")
		if [[ -n "$memsize" ]]; then
			pages=$(($(numfmt --to-unit=Mi --from=iec $memsize)/2))
		else
			pages=200
		fi
		sudo sysctl vm/nr_hugepages=$pages
	fi

	qemu-system-x86_64 \
		-device ich9-intel-hda -device hda-duplex \
		-net nic,model=e1000 -net user \
		-device nec-usb-xhci,id=xhci \
		-device usb-tablet,bus=xhci.0 \
		-enable-kvm -cpu host \
		$@

	if [[ "$@" == *"hugepages"* ]]; then
		sudo sysctl vm/nr_hugepages=0
	fi
}

# with virgl
qemu-gl() {
	qemu \
		-device virtio-vga-gl \
		-display gtk,gl=on \
		$@
}

#
# sandbox
#

##################################################################
# Run sandboxed shell
# Arguments:
#	Same as zsh
##################################################################
sbsh() {
	export SANDBOX=1
	sandbox \
		--ro-bind /run/media /run/media \
		--ro-bind ${XDG_CONFIG_HOME:-$HOME/.config}/zsh ${XDG_CONFIG_HOME:-$HOME/.config}/zsh \
		--ro-bind ${XDG_CONFIG_HOME:-$HOME/.config}/dircolors ${XDG_CONFIG_HOME:-$HOME/.config}/dircolors \
		--bind ${XDG_DATA_HOME:-$HOME/.local/share}/zsh ${XDG_DATA_HOME:-$HOME/.local/share}/zsh \
		$SHELL $*
	unset SANDBOX
}

#
# encryption
#

##################################################################
# wrapper to encrypt a folder with fscrypt
# Arguments:
#	1. folder to encrypt
##################################################################
encrypt() {
	if ! hash fscrypt 2>/dev/null; then
		 err "fscrypt is not installed" && return
	fi

	if [[ $# -ne 1 ]]; then
		echo "Usage $0 folder_to_encrypt"
		return
	fi

	target=$1
	if [[ ! -d "$target" ]]; then
		err "target must be a folder"
	fi

	if [[ -z "$(ls -A $target)" ]]; then
		fscrypt encrypt "$target"
	else
		mkdir "$target.new"
		fscrypt encrypt "$target.new"
		mv "$target" "$target.old"
		mv "$target.new" "$target"
		cp -aT "$target.old"  "$target"
		hash trash 2>/dev/null && trash "$target.old" 
	fi
}

#
# Hardware
#

# Manage conservation mode of ideapad
conservation_mode() {
	usage() {
		echo "\

Usage: $0 <options>

	Battery conservation mode will charge the device to 60% when charge falls
	below 50%, extending the life of the battery.

Options:
	-e		- enable conservation mode
	-d		- disable conservation mode
	-s		- status
"
	}
	local enable_flag=0
	local disable_flag=0
	local status_flag=0
	
	if [[ -e /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode ]]; then
		switch="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
	else
		err "conservation mode is not supported"
	fi

	while getopts ':edsh' opt; do
		case "${opt}" in
			h) 
				usage
				return
				;;
			e) enable_flag=1;;
			d) disable_flag=1;;
			s) status_flag=1;;
			?) 
				err "Invalid option."
				usage
				return 
				;;
		esac
	done

	if (( OPTIND == 1 )); then
		usage
		return
	fi

	if (( status_flag == 1 )); then
		if (( $(cat "$switch") == 1 )); then
			echo "enabled"
		else
			echo "disabled"
		fi
		return
	fi

	if (( enable_flag == 1 )) && (( disable_flag == 1 )); then
		err "-e and -d can not be set at same time"
		return
	fi

	if (( enable_flag == 1)); then
		echo 1 | sudo tee "$switch" >/dev/null &&\
		echo "conservation mode enabled"
	fi
	
	if (( disable_flag == 1)); then
		echo 0 | sudo tee "$switch" >/dev/null &&\
		echo "conservation mode disabled"
	fi
}

#
# Misc
#

help() {
	bash -c "help $*"
}

french() {
	export LC_ALL=fr_FR.UTF-8
}

english() {
	export LC_ALL=en_US.UTF-8
}

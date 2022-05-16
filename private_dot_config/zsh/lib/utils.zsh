#
# Show most used command
function zsh_stats() {
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
function default() {
	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2"   && return 3
}


# Print error message
function err() {
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
function env_default() {
	[[ ${parameters[$1]} = *-export* ]] && return 0
	export "$1=$2" && return 3
}

#
# Proxy
#

##################################################################
# Setup proxy for current session
# default to 127.0.0.1:8888
# Arguments:
#	None
##################################################################
function proxyctl() {
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
-s server		specific server to use (default to http://127.0.0.1:8888)
-e				change desktop environment proxy settings
-g				change git ssh proxy
"
	}
	export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

	local proxy_env=(http_proxy https_proxy HTTP_PROXY HTTPS_PROXY rsync_proxy RSYNC_PROXY)
	local server_url= 	# -s
	local de_flag=0		# -e
	local git_flag=0	# -g
	local cmd=
	local url_regex='(https?|socks([0-9]))://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
	
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

	while getopts ":s:eg" opt; do
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

	
	if [[ -z $server_url ]]; then
		# default server_url
		server_url="http://127.0.0.1:8888/"
	elif [[ ! "$server_url" =~ "$url_regex" ]] then
		# check address syntax
		err "Invalid server url"
		return 1
	fi

	case "$cmd" in
	on)
		;;
	off)
		;;
	status)
		;;
	esac

	echo "
cmd=$cmd
server_url=$server_url
de_flag=$de_flag
git_flag=$git_flag
	"
}
function proxy() {
	export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
	
	export http_proxy="http://127.0.0.1:8888"
	export https_proxy=$http_proxy
	export HTTP_PROXY=$http_proxy
	export HTTPS_PROXY=$http_proxy

	# git
	export ssh_proxy='ProxyCommand ncat --proxy-type socks5 --proxy 127.0.0.1:1080  %h %p'
	git config -f $XDG_CACHE_HOME/git_proxy core.sshCommand "ssh -o '$ssh_proxy'"
}

##################################################################
# Clear proxy for current session
# Arguments:
#	None
##################################################################
function noproxy() {
	unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY ftp_proxy FTP_PROXY

	# git
	unset ssh_proxy
	git config -f $XDG_CACHE_HOME/git_proxy --unset core.sshCommand 
}

#
# Python
#

##################################################################
# Update all python packages
# Arguments:
#	None
##################################################################
function pip_update() {
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
function pacsize() {
	pacman -Qi | awk '/^Name/{name=$3} /^Installed Size/{print $4$5, name}' | sort -h
}

##################################################################
# list files in package by size
# Arguments:
#	1. package
##################################################################
function pacblame() {
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
function  pullall() {
	ls | xargs -P100 -I{} git -C {} pull
}

##################################################################
# Get size of github repo
# Arguments:
#	1. repositorie
##################################################################
function reposize() {
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
function nvidia() {
	export __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json 
}

##################################################################
# Do not use nvidia GPU
# Arguments:
#	None
##################################################################
function nonvidia() {
	unset __NV_PRIME_RENDER_OFFLOAD __GLX_VENDOR_LIBRARY_NAME __VK_LAYER_NV_optimus VK_ICD_FILENAMES
	export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
}


#
# qemu
#

# qemu wrapper
function qemu() {
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
function qemu-gl() {
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
function sbsh() {
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
function encrypt() {
	hash fscrypt 2>/dev/null || { err "fscrypt is not installed" && return }

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
function conservation_mode {
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

function help() {
	bash -c "help $*"
}

function french() {
	export LC_ALL=fr_FR.UTF-8
}

function english() {
	export LC_ALL=en_US.UTF-8
}

#
# Show most used command
function zsh_stats() {
	fc -l 1 \
		| awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' \
		| grep -v "./" | sort -nr | head -20 | column -c3 -s " " -t | nl
}

#
# Set variable "$1" to default value "$2" if "$1" is not yet defined.
#
# Arguments:
#    1. name - The variable to set
#    2. val  - The default value
# Return value:
#    0 if the variable exists, 3 if it was set
#
function default() {
	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2"   && return 3
}

#
# Set environment variable "$1" to default value "$2" if "$1" is not yet defined.
#
# Arguments:
#    1. name - The env variable to set
#    2. val  - The default value
# Return value:
#    0 if the env variable exists, 3 if it was set
#
function env_default() {
	[[ ${parameters[$1]} = *-export* ]] && return 0
	export "$1=$2" && return 3
}

# LOL
function rm {
	if [[ "$#" -eq 2 ]] && [[ "$1" = "-rf" ]] && [[ "$2" = "$HOME" ]]; then
		echo "trying to delete home, Aborting..." 
		return 1
	else
		command rm "$@"
	fi
}

#
# Proxy
#

# Setup proxy for current session
# default to 127.0.0.1:8888
function proxy() {
	export http_proxy="http://127.0.0.1:8888"
	export https_proxy=$http_proxy
	export HTTP_PROXY=$http_proxy
	export HTTPS_PROXY=$http_proxy

	# git
	export ssh_proxy='ProxyCommand ncat --proxy-type socks5 --proxy 127.0.0.1:1080  %h %p'
	git config -f $XDG_CACHE_HOME/git_proxy core.sshCommand "ssh -o '$ssh_proxy'"
}

# Clear proxy for current session
function noproxy() {
	unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy ALL_PROXY ftp_proxy FTP_PROXY

	# git
	unset ssh_proxy
	git config -f $XDG_CACHE_HOME/git_proxy --unset core.sshCommand 
}

#
# Python
#

# Update all python packages
function pip_update() {
	pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip3 install -U
}

function pip_list_outdated() {
	pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 
}


#
# Pacman
#

# list package by size
function pacsize() {
	pacman -Qi | awk '/^Name/{name=$3} /^Installed Size/{print $4$5, name}' | sort -h
}

# list files in package by size
function pacblame() {
	if [[ -z $1 ]]; then
		echo "list files in package by size"
		echo "Usage: pacblame package"
		return 1
	fi
	pacman -Qlq $1 | grep -v '/$' | xargs -r du -h | sort -h

}

# show explicitly installed packages
function pacls() {
	pacman -Qqe | fzf --preview 'pacman -Qil {}' --layout=reverse --bind 'enter:execute(pacman -Qil {} | less)'
}

#
# git
#

# pull all repositories under current folder 
function  pullall() {
	ls | xargs -P100 -I{} git -C {} pull
}

# Get size of github repo
function reposize() {
	[[ -z $1 ]] && echo "Usage: $0 owner/reponame" && return 1
	curl -s https://api.github.com/repos/$1 | jq '.size' | numfmt --to=iec --from-unit=1024
}

#
# Graphics
#

function nvidia() {
	export __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json 
}

function nonvidia() {
	unset __NV_PRIME_RENDER_OFFLOAD __GLX_VENDOR_LIBRARY_NAME __VK_LAYER_NV_optimus VK_ICD_FILENAMES
	export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
}


#
# MISC
#

# virtio-vga-gl for virgil
function qemu() {
	qemu-system-x86_64 \
		-device ich9-intel-hda -device hda-duplex \
		-net nic,model=e1000 -net user \
		-device nec-usb-xhci,id=xhci \
		-device usb-tablet,bus=xhci.0 \
		-enable-kvm -cpu host \
		-device virtio-vga-gl \
		-display gtk,gl=on \
		$@
}

# Bubblewrap sandbox
function sandbox() {
	if [[ "$#" == "0" ]]; then
		echo "Usage $0 <command> [args]"
		return
	fi
	bwrap \
		--ro-bind /usr /usr \
		--symlink /usr/lib /lib \
		--symlink /usr/lib /lib64 \
		--symlink /usr/bin /bin \
		--symlink /usr/bin /sbin \
		--ro-bind /etc /etc \
		--ro-bind /opt /opt \
		--tmpfs /run/user/$UID \
		--ro-bind /run/systemd/resolve /run/systemd/resolve \
		--ro-bind /run/user/$UID/pulse /run/user/$UID/pulse \
		--ro-bind /run/user/$UID/pipewire-0 /run/user/$UID/pipewire-0 \
		--ro-bind /run/user/$UID/pipewire-0.lock /run/user/$UID/pipewire-0.lock \
		--ro-bind /run/user/$UID/wayland-0 /run/user/$UID/wayland-0 \
		--ro-bind /run/user/$UID/wayland-0.lock /run/user/$UID/wayland-0.lock \
		--tmpfs /tmp \
		--proc /proc \
		--dev /dev \
		--dev-bind /dev/dri /dev/dri \
		--dev-bind /dev/nvidia0 /dev/nvidia0 \
		--dev-bind /dev/nvidia-caps /dev/nvidia-caps \
		--dev-bind /dev/nvidiactl /dev/nvidiactl \
		--dev-bind /dev/nvidia-modeset /dev/nvidia-modeset \
		--dev-bind /dev/nvidia-uvm /dev/nvidia-uvm \
		--dev-bind /dev/nvidia-uvm-tools /dev/nvidia-uvm-tools \
		--ro-bind /sys /sys \
		--bind /home/arthur/Downloads /home/arthur/Downloads \
		--bind /home/arthur/tmp /home/arthur/tmp \
		--ro-bind /home/arthur/.config/zsh /home/arthur/.config/zsh \
		--ro-bind /home/arthur/.config/dircolors /home/arthur/.config/dircolors \
		--bind /home/arthur/.local/share/zsh /home/arthur/.local/share/zsh \
		--bind /home/arthur/.cache /home/arthur/.cache \
		--unshare-all \
		--share-net \
		--die-with-parent \
	$@
}

# Run sandboxed shell
function sbsh {
	export SANDBOX=1
	sandbox $SHELL
	unset SANDBOX
}

function help() {
	bash -c "help $*"
}

function french() {
	export LC_ALL=fr_FR.UTF-8
}

function english() {
	export LC_ALL=en_US.UTF-8
}

#!/bin/bash

if [[ -f /etc/os-release ]]; then
	. /etc/os-release
else
	echo "missing os-release file"
fi

arch_linux() {
	packages=(
		aria2 asp at atop bat bc bear borg borgmatic btop delve duf dust fd
		foot go lf llvm make mpv neovim nmap nvtop pgcli ripgrep sd rsync
		wl-clipboard
	)
	sudo pacman -S --needed "${packages[@]}"
}

case $ID in
arch) arch_linux ;;
esac

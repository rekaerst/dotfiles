#!/bin/bash

src_dir=$(chezmoi source-path)

err() {
	echo >&2 -e "\e[31;1m$*\e[0m"
}

if [[ -d "$src_dir/etc/" ]]; then
	sudo rsync -avn "$src_dir/etc/" /etc
else
	err "$src_dir/etc not found"
	exit 1
fi

# update hwdb binary
sudo systemd-hwdb update && sudo udevadm trigger

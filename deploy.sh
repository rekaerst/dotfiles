#!/bin/bash

cd "${XDG_CONFIG_HOME:-$HOME/.config}" || { 
	echo "failed to change the working directory"
	exit 255;
}

if [[ ! -d "${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles" ]]; then
	echo "dotfiles directory not found"
	exit 255
fi


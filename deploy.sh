#!/bin/bash

DOTFILES="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"

if [[ ! -d "$DOTFILES" ]]; then
	echo "dotfiles directory not found"
	exit 255
fi

# programs that follows XDG
cd "${XDG_CONFIG_HOME:-$HOME/.config}" || {
	echo "failed to change the working directory"
	exit 255
}

config_xdg=(
	bat borgmatic.d environment.d fontconfig foot fsh git go jrnl Kvantum less
	lf litecli luarocks MangoHud mpv mycli npm nvim nvtop pgcli pip pylint rc.d
	readline sway systemd task tmux zsh bookmarks chrome-flags.conf clang-format
	dircolors dxvk.conf flake8 qt5ct qt6ct
)

for i in "${config_xdg[@]}"; do
	ln -sf "dotfiles/$i" .
done

# programs that puts dotfile inside $HOME

cd "$HOME" || {
	echo "failed to change the working directory"
	exit 255
}

ln -sf ".config/dotfiles/bashrc" .bashrc

# systemd
systemctl --user enable rc.service

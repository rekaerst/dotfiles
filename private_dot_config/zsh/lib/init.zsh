SRC="$(dirname "$0")"
source $SRC/utils.zsh
source $SRC/appearance.zsh
source $SRC/alias.zsh
source $SRC/termtitle.zsh
source $SRC/options.zsh
source $SRC/completion.zsh
source $SRC/keybinding.zsh
[[ -z "$SANDBOX" ]] || source $SRC/sandbox.zsh
unset SRC

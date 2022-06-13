SRC="$(dirname "$0")"
source $SRC/utils.zsh
source $SRC/options.zsh
source $SRC/appearance.zsh
source $SRC/p10k.zsh
source $SRC/alias.zsh
source $SRC/directory.zsh
source $SRC/termtitle.zsh
source $SRC/keybinding.zsh
source $SRC/completion.zsh
source $SRC/fzf.zsh
[[ -f "$SRC/secrets.zsh" ]] && source $SRC/secrets.zsh
[[ -n "$SANDBOX" ]] && source $SRC/sandbox.zsh
unset SRC

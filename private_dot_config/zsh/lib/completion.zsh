# user defined functions
fpath+=($ZDOTDIR/lib/functions)
autoload -U $ZDOTDIR/lib/functions/*(.:t)

compdef _vim vi
compdef _command sandbox
compdef _grc grc
compdef _pacman_completions_installed_packages pacblame
compdef _zsh sbsh
compdef -d play

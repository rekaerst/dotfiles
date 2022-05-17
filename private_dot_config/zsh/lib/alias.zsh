#!/bin/zsh

# use proxy for httping
alias httping="httping -E"
# use sudo for alias
alias sudo='sudo '
# task
alias taskui="taskwarrior-tui"
# dotfiles
alias dflg="lazygit -p $(chezmoi source-path)"
alias dotfiles="cd $(chezmoi source-path)"
# git
alias lg="lazygit"
alias pacfzf="fzf --preview 'pacman -Sil {}' --layout=reverse --bind 'enter:execute(pacman -Qil {} | less)'"
# misc
alias html2pdf='wkhtmltopdf'
alias info='info --vi-keys'
alias th=trash
alias rename=perl-rename
alias hs="python -m http.server"
alias locate='locate --regex'
alias R="R --quiet"
alias jitrocks="luarocks --lua-version 5.1"
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'

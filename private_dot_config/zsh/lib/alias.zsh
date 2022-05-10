#!/bin/zsh

alias svn='svn --config-dir $XDG_CONFIG_HOME/subversion'
alias info='info --vi-keys'
alias httping="httping -E"
alias sudo='sudo '
alias html2pdf='wkhtmltopdf'
alias th=trash
alias locate='locate --regex'
alias lsof='lsof -n'
alias hs="python -m http.server"
alias R="R --quiet"
alias rename=perl-rename
alias jitrocks="luarocks --lua-version 5.1"
alias taskui="taskwarrior-tui"
alias _='sudo '
alias dotfiles="cd $(chezmoi source-path)"
alias dfgit="lazygit -p $(chezmoi source-path)"

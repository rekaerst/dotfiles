bindkey '^[OP' run-help

# allow ctrl-A and ctrl-E to move to beginning/end of line
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# remove ESC bindings
bindkey -r '^[,'
bindkey -r '^[/'
bindkey -r '^[~'
bindkey -r '^[^[[C'
bindkey -r '^[^[[D'

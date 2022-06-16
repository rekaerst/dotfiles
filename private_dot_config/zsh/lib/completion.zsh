[[ ${TERM} != dumb ]] && () {
# user defined functions
fpath+=($ZDOTDIR/lib/functions)
autoload -U $ZDOTDIR/lib/functions/*(.:t)

# init
zmodload -i zsh/complist
autoload -Uz compinit && compinit -C -d ${ZSH_CACHE_DIR}/zcompdump

# cache
if [[ ! ${zdumpfile}.zwc -nt ${zdumpfile} ]] zcompile ${ZSH_CACHE_DIR}/zcompdump
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ${ZSH_CACHE_DIR}/zcompcache

# Move cursor to end of word if a full completion is inserted.
setopt always_to_end
# Make globbing case insensitive.
setopt no_case_glob
# Don't beep on ambiguous completions.
setopt no_list_beep

# Menu
bindkey -M menuselect '^M' .accept-line
zstyle ':completion:*:*:*:*:*' menu select search

# Format
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' '+r:|?=**'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'

# Ignore useless commands and functions
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec)|prompt_*)'

# Array completion element sorting.
zstyle ':completion:*:*:-subscript-:*' tag-order 'indexes' 'parameters'

# Directories
if (( ${+LS_COLORS} )); then
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
else
  # Use same LS_COLORS definition from utility module, in case it was not set
  zstyle ':completion:*:default' list-colors ${(s.:.):-di=1;34:ln=35:so=32:pi=33:ex=31:bd=1;36:cd=1;33:su=30;41:sg=30;46:tw=30;42:ow=30;43}
fi
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*' squeeze-slashes true

# History
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

zstyle -e ':completion:*:hosts' hosts 'reply=(
    ${=${=${=${${(f)"$(cat {/etc/ssh/ssh_,~/.ssh/}known_hosts{,2} 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
    ${=${(f)"$(cat /etc/hosts 2>/dev/null; ypcat hosts 2>/dev/null)"}%%(\#)*}
    ${=${${${${(@M)${(f)"$(cat ~/.ssh/config{,.d/*(N)} 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
  )'

# Don't complete uninteresting users...
zstyle ':completion:*:*:*:users' ignored-patterns \
	'_*' adm amanda apache avahi beaglidx bin cacti canna clamav daemon dbus \
	distcache dovecot fax ftp games gdm gkrellmd gopher hacluster haldaemon \
	halt hsqldb ident junkbust ldap lp mail mailman mailnull mldonkey mysql \
	nagios named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
	operator pcap postfix postgres privoxy pulse pvm quagga radvd rpc rpcuser \
	rpm shutdown squid sshd sync uucp vcsa xfs

# ... unless we really want to.
zstyle '*' single-ignored show

# Ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'

# custom completion

# heroku autocomplete setup
HEROKU_AC_ZSH_SETUP_PATH=/home/arthur/.cache/heroku/autocomplete/zsh_setup && test -f $HEROKU_AC_ZSH_SETUP_PATH && source $HEROKU_AC_ZSH_SETUP_PATH;

# compdef
compdef _vim vi
compdef _command sandbox
compdef _grc grc
compdef _pacman_completions_installed_packages pacblame
compdef _zsh sbsh
compdef _pkg-config pkgconf
# NOTE: play framework conflicts with sox
compdef -d play
}


function zsh_stats() {
	fc -l 1 \
		| awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' \
		| grep -v "./" | sort -nr | head -20 | column -c3 -s " " -t | nl
	}

function take() {
	mkdir -p $@ && cd ${@:$#}
}

function open_command() {
	local open_cmd

  # define the open command
  case "$OSTYPE" in
	  darwin*)  open_cmd='open' ;;
	  cygwin*)  open_cmd='cygstart' ;;
	  linux*)   [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='nohup xdg-open' || {
		  open_cmd='cmd.exe /c start ""'
				[[ -e "$1" ]] && { 1="$(wslpath -w "${1:a}")" || return 1 }
			} ;;
	msys*)    open_cmd='start ""' ;;
	*)        echo "Platform $OSTYPE not supported"
		return 1
		;;
esac

${=open_cmd} "$@" &>/dev/null
}

#
# Get the value of an alias.
#
# Arguments:
#    1. alias - The alias to get its value from
# STDOUT:
#    The value of alias $1 (if it has one).
# Return value:
#    0 if the alias was found,
#    1 if it does not exist
#
function alias_value() {
	(( $+aliases[$1] )) && echo $aliases[$1]
}

#
# Try to get the value of an alias,
# otherwise return the input.
#
# Arguments:
#    1. alias - The alias to get its value from
# STDOUT:
#    The value of alias $1, or $1 if there is no alias $1.
# Return value:
#    Always 0
#
function try_alias_value() {
	alias_value "$1" || echo "$1"
}

#
# Set variable "$1" to default value "$2" if "$1" is not yet defined.
#
# Arguments:
#    1. name - The variable to set
#    2. val  - The default value
# Return value:
#    0 if the variable exists, 3 if it was set
#
function default() {
	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2"   && return 3
}

#
# Set environment variable "$1" to default value "$2" if "$1" is not yet defined.
#
# Arguments:
#    1. name - The env variable to set
#    2. val  - The default value
# Return value:
#    0 if the env variable exists, 3 if it was set
#
function env_default() {
	[[ ${parameters[$1]} = *-export* ]] && return 0
	export "$1=$2" && return 3
}


# Required for $langinfo
zmodload zsh/langinfo

# URL-encode a string
#
# Encodes a string using RFC 2396 URL-encoding (%-escaped).
# See: https://www.ietf.org/rfc/rfc2396.txt
#
# By default, reserved characters and unreserved "mark" characters are
# not escaped by this function. This allows the common usage of passing
# an entire URL in, and encoding just special characters in it, with
# the expectation that reserved and mark characters are used appropriately.
# The -r and -m options turn on escaping of the reserved and mark characters,
# respectively, which allows arbitrary strings to be fully escaped for
# embedding inside URLs, where reserved characters might be misinterpreted.
#
# Prints the encoded string on stdout.
# Returns nonzero if encoding failed.
#
# Usage:
#  omz_urlencode [-r] [-m] [-P] <string>
#
#    -r causes reserved characters (;/?:@&=+$,) to be escaped
#
#    -m causes "mark" characters (_.!~*''()-) to be escaped
#
#    -P causes spaces to be encoded as '%20' instead of '+'
function omz_urlencode() {
	emulate -L zsh
	local -a opts
	zparseopts -D -E -a opts r m P

	local in_str=$1
	local url_str=""
	local spaces_as_plus
	if [[ -z $opts[(r)-P] ]]; then spaces_as_plus=1; fi
	local str="$in_str"

  # URLs must use UTF-8 encoding; convert str to UTF-8 if required
  local encoding=$langinfo[CODESET]
  local safe_encodings
  safe_encodings=(UTF-8 utf8 US-ASCII)
  if [[ -z ${safe_encodings[(r)$encoding]} ]]; then
	  str=$(echo -E "$str" | iconv -f $encoding -t UTF-8)
	  if [[ $? != 0 ]]; then
		  echo "Error converting string from $encoding to UTF-8" >&2
		  return 1
	  fi
  fi

  # Use LC_CTYPE=C to process text byte-by-byte
  local i byte ord LC_ALL=C
  export LC_ALL
  local reserved=';/?:@&=+$,'
  local mark='_.!~*''()-'
  local dont_escape="[A-Za-z0-9"
  if [[ -z $opts[(r)-r] ]]; then
	  dont_escape+=$reserved
  fi
  # $mark must be last because of the "-"
  if [[ -z $opts[(r)-m] ]]; then
	  dont_escape+=$mark
  fi
  dont_escape+="]"

  # Implemented to use a single printf call and avoid subshells in the loop,
  # for performance (primarily on Windows).
  local url_str=""
  for (( i = 1; i <= ${#str}; ++i )); do
	  byte="$str[i]"
	  if [[ "$byte" =~ "$dont_escape" ]]; then
		  url_str+="$byte"
	  else
		  if [[ "$byte" == " " && -n $spaces_as_plus ]]; then
			  url_str+="+"
		  else
			  ord=$(( [##16] #byte ))
			  url_str+="%$ord"
		  fi
	  fi
  done
  echo -E "$url_str"
}

# URL-decode a string
#
# Decodes a RFC 2396 URL-encoded (%-escaped) string.
# This decodes the '+' and '%' escapes in the input string, and leaves
# other characters unchanged. Does not enforce that the input is a
# valid URL-encoded string. This is a convenience to allow callers to
# pass in a full URL or similar strings and decode them for human
# presentation.
#
# Outputs the encoded string on stdout.
# Returns nonzero if encoding failed.
#
# Usage:
#   omz_urldecode <urlstring>  - prints decoded string followed by a newline
function omz_urldecode {
	emulate -L zsh
	local encoded_url=$1

  # Work bytewise, since URLs escape UTF-8 octets
  local caller_encoding=$langinfo[CODESET]
  local LC_ALL=C
  export LC_ALL

  # Change + back to ' '
  local tmp=${encoded_url:gs/+/ /}
  # Protect other escapes to pass through the printf unchanged
  tmp=${tmp:gs/\\/\\\\/}
  # Handle %-escapes by turning them into `\xXX` printf escapes
  tmp=${tmp:gs/%/\\x/}
  local decoded
  eval "decoded=\$'$tmp'"

  # Now we have a UTF-8 encoded string in the variable. We need to re-encode
  # it if caller is in a non-UTF-8 locale.
  local safe_encodings
  safe_encodings=(UTF-8 utf8 US-ASCII)
  if [[ -z ${safe_encodings[(r)$caller_encoding]} ]]; then
	  decoded=$(echo -E "$decoded" | iconv -f UTF-8 -t $caller_encoding)
	  if [[ $? != 0 ]]; then
		  echo "Error converting string from UTF-8 to $caller_encoding" >&2
		  return 1
	  fi
  fi

  echo -E "$decoded"
}
#!/bin/zsh

function rm {
	if [[ "$#" -eq 2 ]] && [[ "$1" = "-rf" ]] && [[ "$2" = "$HOME" ]]; then
		echo "trying to delete home, Aborting..." 
		return 1
	else
		command rm "$@"
	fi
}

#
# Setup proxy for current session
# default to 127.0.0.1:8889
function proxy() {
	export http_proxy="http://127.0.0.1:8888"
	export https_proxy=$http_proxy
	export HTTP_PROXY=$http_proxy
	export HTTPS_PROXY=$http_proxy
	echo "use-proxy=yes" > $WGETRC
	echo "http_proxy=$http_proxy" >> $WGETRC
	echo "https_proxy=$http_proxy" >> $WGETRC
}

#
# Clear proxy for current session
function noproxy() {
	unset http_proxy
	unset https_proxy
	unset HTTP_PROXY
	unset HTTPS_PROXY
	unset all_proxy
	unset ALL_PROXY
	unset ftp_proxy
	unset FTP_PROXY
	:> $WGETRC
}

function pipupgradeall() {
	pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip3 install -U
}

function help() {
	bash -c "help $*"
}

#
# Print list of installed packages sorted by installed size
# Arguments:
#    1. limit - The maximum output rows
function debsort() {
	dpkg-query --show --showformat='${Installed-Size}\t${Package}\n' | sort -rh | head -n ${1:-10} | awk '{print $1/1024, $2}'
}

#
# Purge config files for uninstalled packages
function debpurge() {
	dpkg -l | grep '^rc' | cut -d ' ' -f 3 | sudo xargs dpkg --purge
}

function pacsize() {
	pacman -Qi | awk '/^Name/{name=$3} /^Installed Size/{print $4$5, name}' | sort -h
}

# find largest packages
function pacblame() {
	if [[ -z $1 ]]; then
		echo "Listing files owned by a package with size"
		echo "Usage: pacblame package"
		return 1
	fi
	pacman -Qlq $1 | grep -v '/$' | xargs -r du -h | sort -h

}

# show explicitly installed packages
function pacls() {
	pacman -Qqe | fzf --preview 'pacman -Qil {}' --layout=reverse --bind 'enter:execute(pacman -Qil {} | less)'
}

# pull all repositories under current folder 
function  pullall() {
	ls | xargs -P100 -I{} git -C {} pull
}


function list_outdated_pip_package() {
	pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 
}

function french() {
	export LC_ALL=fr_FR.UTF-8
}

function english() {
	export LC_ALL=en_US.UTF-8
}

#
# Get size of github repo
function reposize() {
	[[ -z $1 ]] && echo "Usage: $0 owner/reponame" && return 1
	curl -s https://api.github.com/repos/$1 | jq '.size' | numfmt --to=iec --from-unit=1024
}

function nvidia() {
	export __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json 
}

function nonvidia() {
	unset __NV_PRIME_RENDER_OFFLOAD __GLX_VENDOR_LIBRARY_NAME __VK_LAYER_NV_optimus VK_ICD_FILENAMES
	export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
}

# virtio-vga-gl for virgil
function qemu() {
	qemu-system-x86_64 \
		-device ich9-intel-hda -device hda-duplex \
		-net nic,model=e1000 -net user \
		-device nec-usb-xhci,id=xhci \
		-device usb-tablet,bus=xhci.0 \
		-enable-kvm -cpu host \
		-device virtio-vga-gl \
		-display gtk,gl=on \
		$@
	}

#!/bin/bash

# nginx server
if [[ -d "$HOME/srv" ]] && [[ -d "$HOME/src" ]] && [[ -d "$HOME/src/local" ]]; then
	setfacl -m "g:http:r-x" "$HOME" "$HOME/srv" "$HOME/src" "$HOME/src/local"
fi

#!/bin/bash

# nginx server
setfacl -m "g:http:r-x" "$HOME" "$HOME/srv" "$HOME/src" "$HOME/src/local"

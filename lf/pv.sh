#!/bin/sh

case "$1" in
    *.tar*) tar tf "$1";;
    *.zip) unzip -l "$1";;
    *.rar) unrar l "$1";;
    *.7z) 7z l "$1";;
    *.pdf) pdftotext "$1" -;;
    *.md) glow -s dark "$1";;
    *) highlight -O truecolor --force --config-file="${XDG_CONFIG_HOME:-$HOME/.config}/lf/highlight.theme" "$1";;
esac

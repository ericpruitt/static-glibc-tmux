#!/bin/sh
# Wrapper script to enable the tmux man page to be shown by running tmux with
# "man" or "help" as the first argument.
scriptdir="$(dirname "$(readlink -f "$0")")"
if [ "$1" = man ] || [ "$1" = help ]; then
    MANSECT=1 MANPATH="$scriptdir/" exec man tmux
else
    exec "$scriptdir/tmux" "$@"
fi

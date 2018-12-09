#!/bin/bash
#
# Either register this hook directly to CMUs or put the bottom command into your
# own hook script.
# To register a/this script make sure that it is executable, open CMus and enter
# the following command:
# > :set status_display_program=/PATH/TO/SCRIPT

# Define where to store the FIFO
[[ -z "$XDG_RUNTIME_DIR" ]] && XDG_RUNTIME_DIR="/tmp"
fifo="$XDG_RUNTIME_DIR/powerstatus10k/fifos/cmus"

# Pipe arguments to the Powerstatus10k FIFO.
printf "%s\\n" "$*" > "$fifo" &

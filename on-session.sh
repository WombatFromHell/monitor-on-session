#!/usr/bin/env bash

if [ "$1" == "true" ]; then
	#
	# this runs when the session goes into a locked state
	#
	echo ""
elif [ "$1" == "false" ]; then
	#
	# these things run when the session goes into an unlocked state
	#
	# do a refresh rate toggle to fix gsync on Nvidia cards
	# ... at least until the next Monitor Suspend/Power event
	$HOME/.local/bin/fix-gsync.sh
fi

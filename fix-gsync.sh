#!/bin/sh
OUTPUT=DP-4

if [ "$XDG_SESSION_TYPE" = "x11" ]; then
	xrandr --output ${OUTPUT} -r 120 --mode 2560x1440
	sleep 1
	xrandr --output ${OUTPUT} -r 144 --mode 2560x1440
	"$@"
fi

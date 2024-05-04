#!/usr/bin/env bash

OUTPUT="DP-4"
XRANDR=$(command -v xrandr)

if ! command -v nvidia-settings &>/dev/null; then
	echo "ERROR: nvidia-settings not found in PATH, aborting!"
	exit 1
fi
VRR_ENABLED=$(nvidia-settings -q AllowVRR | awk -F':' '/Attribute/ {print $3}' | sed 's/^ //;s/\.//g')

if [ "$XDG_SESSION_TYPE" = "x11" ] && [ "$VRR_ENABLED" -eq 1 ]; then
	"$XRANDR" --output "$OUTPUT" -r 120 --mode 2560x1440
	sleep 1
	"$XRANDR" --output "$OUTPUT" -r 144 --mode 2560x1440
	"$@"
elif ! [ "$XDG_SESSION_TYPE" = "x11" ]; then
	echo "Warning: not running in X11 session! XRANDR will not work!"
elif [ "$VRR_ENABLED" -eq 0 ]; then
	echo "Warning: VRR is not enabled, aborting!"
fi

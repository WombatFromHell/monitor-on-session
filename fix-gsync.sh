#!/usr/bin/env bash
set -euxo pipefail

OUTPUT="DP-4"
XRANDR=$(command -v xrandr)

if [ "$XDG_SESSION_TYPE" = "x11" ]; then
	"$XRANDR" --output "$OUTPUT" -r 120 --mode 2560x1440
	sleep 1
	"$XRANDR" --output "$OUTPUT" -r 144 --mode 2560x1440
	"$@"
else
	echo "Warning: not running in X11 session! XRANDR will not work!"
fi

#!/usr/bin/env bash

OUTPUT="DP-4"
XRANDR=$(command -v xrandr)

get_current_primary_monitor() {
  SELECTED=$(xrandr | grep " connected primary " | awk '{print $1}')
  echo "$SELECTED"
}
CURRENT_PRIMARY=$(get_current_primary_monitor)

if ! command -v nvidia-settings &>/dev/null; then
  echo "ERROR: nvidia-settings not found in PATH, aborting!"
  exit 1
fi
VRR_ENABLED=$(nvidia-settings -q AllowVRR | awk -F':' '/Attribute/ {print $3}' | sed 's/^ //;s/\.//g')

if [ "$XDG_SESSION_TYPE" = "x11" ] && ! [[ "$DESKTOP_SESSION" = *gnome* ]] && [ "$VRR_ENABLED" -eq 1 ] && [ "$CURRENT_PRIMARY" = "$OUTPUT" ]; then
  "$XRANDR" --output "$OUTPUT" -r 120 --mode 2560x1440
  sleep 1
  "$XRANDR" --output "$OUTPUT" -r 144 --mode 2560x1440
  "$@"
elif ! [ "$XDG_SESSION_TYPE" = "x11" ]; then
  echo "Warning: not running in X11 session! XRANDR will not work!"
  exit 1
elif [ "$VRR_ENABLED" -eq 0 ]; then
  echo "Warning: VRR is not enabled, aborting!"
  exit 1
elif ! [ "$CURRENT_PRIMARY" = "$OUTPUT" ]; then
  echo "Warning: the current primary monitor is not $OUTPUT!"
  exit 1
fi

exit 0

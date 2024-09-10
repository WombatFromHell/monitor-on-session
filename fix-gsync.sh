#!/usr/bin/env bash

X11_OUTPUT="DP-4"
WAYLAND_OUTPUT="DP-3"
XRANDR=$(command -v xrandr)
KSD=$(command -v kscreen-doctor)
KSID=$(command -v kscreen-id.py)

get_current_primary_monitor_x11() {
  SELECTED=$(xrandr | grep " connected primary " | awk '{print $1}')
  echo "$SELECTED"
}
CURRENT_PRIMARY_X11=$(get_current_primary_monitor_x11)
CURRENT_PRIMARY=$("$KSID" --current)

if ! command -v nvidia-settings &>/dev/null; then
  echo "ERROR: nvidia-settings not found in PATH, aborting!"
  exit 1
fi

if [ "$XDG_SESSION_TYPE" = "x11" ]; then
  VRR_ENABLED_X11=$(nvidia-settings -q AllowVRR | awk -F':' '/Attribute/ {print $3}' | sed 's/^ //;s/\.//g')
  if [ "$VRR_ENABLED_X11" -eq 1 ] && [ "$CURRENT_PRIMARY_X11" = "$X11_OUTPUT" ]; then
    "$XRANDR" --output "$X11_OUTPUT" -r 60 --mode 2560x1440
    sleep 1
    "$XRANDR" --output "$X11_OUTPUT" -r 144 --mode 2560x1440
    "$@"
  elif ! [ "$CURRENT_PRIMARY_X11" = "$X11_OUTPUT" ]; then
    echo "Warning: the current primary monitor does not match our defined output!"
    exit 1
  elif ! [ "$VRR_ENABLED_X11" -eq 1 ]; then
    echo "Warning: VRR is not enabled, aborting!"
    exit 1
  else
    echo "Error: an unknown error occurred when attempting to detect active output!"
    exit 1
  fi
elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
  VRR_ENABLED=$("$KSID" --vrr | cut -d' ' -f2)
  if [ "$VRR_ENABLED" = "True" ] && [ "$CURRENT_PRIMARY" = "$WAYLAND_OUTPUT" ]; then
    targetm1_mode=$("$KSID" --mid "$WAYLAND_OUTPUT" 2560x1440@120)
    targetm0_mode=$("$KSID" --mid "$WAYLAND_OUTPUT" 2560x1440@144)
    "$KSD" output."$WAYLAND_OUTPUT".mode."$targetm1_mode" # switch to 120hz
    sleep 1
    "$KSD" output."$WAYLAND_OUTPUT".mode."$targetm0_mode" # switch back to 144hz
    "$@"
  elif ! [ "$CURRENT_PRIMARY" = "$WAYLAND_OUTPUT" ]; then
    echo "Warning: the current primary monitor does not match our defined output!"
    exit 1
  elif ! [ "$VRR_ENABLED" = "True" ]; then
    echo "Warning: VRR is not enabled, aborting!"
    exit 1
  else
    echo "Error: an unknown error occurred when attempting to detect active output!"
    exit 1
  fi
else
  echo "Error: an unknown session type was detected!"
  exit 1
fi

exit 0

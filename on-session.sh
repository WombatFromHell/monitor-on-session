#!/usr/bin/env bash

if [ "$1" == "true" ]; then
  # do nothing here
  sleep 1
elif [ "$1" == "false" ]; then
  # do a refresh rate toggle to fix gsync on Nvidia cards
  # ... at least until the next Monitor Suspend/Power event
  sleep 2 && "$HOME"/.local/bin/fix-gsync.sh
  "$HOME"/.local/bin/openrgb-load.sh
fi

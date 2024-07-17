#!/usr/bin/env bash
# Path to the script to run when the signal is received
SCRIPT_PATH="${1:-$HOME/.local/bin/on-session.sh}"
LOG_FILE="/tmp/unlock_monitor.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"$LOG_FILE"
}

handle_signal() {
  log "Screen lock state changed to: $1"
  log "Running: $SCRIPT_PATH $1"
  if [[ -x "$SCRIPT_PATH" ]]; then
    "$SCRIPT_PATH" "$1"
  else
    log "Error: $SCRIPT_PATH is not executable or does not exist."
  fi
}

detect_desktop_environment() {
  if [[ -n "$XDG_CURRENT_DESKTOP" ]]; then
    echo "$XDG_CURRENT_DESKTOP"
  elif [[ -n "$DESKTOP_SESSION" ]]; then
    echo "$DESKTOP_SESSION"
  elif pgrep gnome-shell >/dev/null; then
    echo "GNOME"
  elif pgrep plasmashell >/dev/null; then
    echo "KDE"
  else
    echo "UNKNOWN"
  fi
}

if [[ ! -x "$SCRIPT_PATH" ]]; then
  echo "Error: $SCRIPT_PATH is not executable or does not exist."
  exit 1
fi

DE=$(detect_desktop_environment)
log "Detected desktop environment: $DE"

case "$DE" in
*GNOME*)
  DBUS_INTERFACE="org.gnome.ScreenSaver"
  OBJECT_PATH="/org/gnome/ScreenSaver"
  ;;
*KDE*)
  DBUS_INTERFACE="org.freedesktop.ScreenSaver"
  OBJECT_PATH="/org/freedesktop/ScreenSaver"
  ;;
*)
  log "Unsupported desktop environment: $DE"
  exit 1
  ;;
esac

log "Starting screen lock monitor for $DE"

dbus-monitor --session "type='signal',interface='$DBUS_INTERFACE'" |
  while read -r line; do
    if [[ "$line" == *"member=ActiveChanged"* ]]; then
      active=$(dbus-send --session --print-reply --dest="$DBUS_INTERFACE" \
        "$OBJECT_PATH" "$DBUS_INTERFACE.GetActive")
      state=$(echo "$active" | awk '/boolean/ {print $2}')
      if [[ "$state" != "$prev_state" ]]; then
        handle_signal "$state"
        prev_state="$state"
      fi
    fi
  done

log "Screen lock monitor stopped"

#!/usr/bin/env bash
# Path to the script to run when the signal is received
SCRIPT_PATH="${@:-$HOME/.local/bin/on-session.sh}"

handle_signal() {
	echo "Screen saver active state changed to: $1"
	echo "Running: $SCRIPT_PATH $1"
	$SCRIPT_PATH $1
}

dbus-monitor --session "type='signal',interface='org.freedesktop.ScreenSaver'" | (
	while true; do
		read -r line
		if [[ "$line" == *"member=ActiveChanged"* ]]; then
			object_path=$(echo "$line" | awk -F'path=' '{print $2}' | awk -F';' '{print $1}')
			active=$(dbus-send --session --print-reply --dest=org.freedesktop.ScreenSaver "$object_path" org.freedesktop.ScreenSaver.GetActive)
			state=$(echo "$active" | awk '/boolean/ {print $2}' | tr -d '"')
			if [ "$state" != "$prev_state" ]; then
				handle_signal "$state"
				prev_state="$state"
			fi
		fi
	done
)

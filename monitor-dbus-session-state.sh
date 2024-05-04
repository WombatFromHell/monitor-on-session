#!/usr/bin/env bash

lock_scripts=()
unlock_scripts=("$HOME/.local/bin/fix-gsync.sh")

run_scripts() {
	for script in "${@}"; do
		"$script"
		exit_code=$?
		if [ "$exit_code" -ne 0 ]; then
			echo "Error: $script exited with code $exit_code"
		fi
	done
}

handle_signal() {
	echo "Screen saver active state changed to: $1"

	if [ "$1" == "true" ]; then
		#
		# this runs when the session goes into a locked state
		#
		echo "Running lock state scripts..."
		run_scripts "${lock_scripts[@]}"
	elif [ "$1" == "false" ]; then
		#
		# these things run when the session goes into an unlocked state
		#
		echo "Running unlock state scripts..."
		run_scripts "${unlock_scripts[@]}"
	fi
}

prev_state=""
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

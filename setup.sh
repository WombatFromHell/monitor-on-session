#!/usr/bin/env bash

help() {
	echo "$0 [install | uninstall]"
	echo "    install       installs the scripts and immediately enables the user service"
	echo "    uninstall     uninstalls the scripts and immediately disables the user service"
	exit 1
}

if [ "$1" == "install" ]; then
	mkdir -p $HOME/.config/systemd/user
	mkdir -p $HOME/.local/bin
	cp -f on-session-state.service $HOME/.config/systemd/user/
	cp -f ./*.sh $HOME/.local/bin/
	chmod 0755 $HOME/.local/bin/{monitor-dbus-session-state,fix-gsync,on-session}.sh
	systemctl --user daemon-reload &&
		systemctl --user enable --now on-session-state.service
	echo "Installed the on-session-state.service unit!"
elif [ "$1" == "uninstall" ]; then
	systemctl --user disable --now on-session-state.service
	rm -f $HOME/.config/systemd/user/on-session-state.service
	rm -f $HOME/.local/bin/{monitor-dbus-session-state,fix-gsync,on-session}.sh
	systemctl --user daemon-reload
	echo "Uninstalled the on-session-state.service unit!"
else
	help
fi

exit 0

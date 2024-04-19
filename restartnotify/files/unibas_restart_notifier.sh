#!/bin/bash

# Get the list of logged-in users
USERS=$(who | grep "tty" | awk '{print $1}' | sort -u)

# Message to be displayed
TITLE="Restart Recommended"
MESSAGE="A kernel update has recently been installed. Unibas IT-Services recommends to restart your computer before continuing your work."
LOGO=/usr/local/share/restartnotify/unibas_logo.png

# Check if the trigger file has been set
if [[ -e /tmp/unibas_restart_notifier_trigger && -n $USERS ]]; then
        # Loop through each user and display the notification
        for USER in $USERS; do
                # Run notify-send in the user's session
                sudo -u $USER DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u $USER)/bus notify-send -i $LOGO -u critical "$TITLE" "$MESSAGE"
        done
        wall "$MESSAGE"
        rm /tmp/unibas_restart_notifier_trigger
fi

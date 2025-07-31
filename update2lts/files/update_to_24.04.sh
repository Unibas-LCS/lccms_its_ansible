#!/bin/bash
DELAY="$(gsettings get org.gnome.desktop.session idle-delay | cut -d ' ' -f2)"
gsettings set org.gnome.desktop.session idle-delay 0
sudo /opt/update_to_24.04_update.sh
OUTPUT=$?
gsettings set org.gnome.desktop.session idle-delay $DELAY
if [ $OUTPUT -eq 0 ]; then
    reboot
fi
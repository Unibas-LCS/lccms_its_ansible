#!/bin/bash
# This script will check for the last or still logged in user(s)

# Until we know whether this could create a problem with the data protection laws.
echo "-"
exit 0

current_users=$(/usr/bin/who | /usr/bin/awk '{print $1}' | /usr/bin/sort -u)

if [ -n "$current_users" ]; then
    /usr/bin/printf '%s\n' $current_users
else
    # No current users — get most recent user (excluding reboot/wtmp lines)
    last_user=$(/usr/bin/last -w | /usr/bin/awk '!/reboot|wtmp/ {print $1; exit}')
    [ -n "$last_user" ] && echo "$last_user"
fi

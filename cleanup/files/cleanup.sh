#!/bin/bash

/usr/bin/tput setaf 15
/usr/bin/date

# Detect Flatpak and Snap
HAS_FLATPAK=0
HAS_SNAP=0

if command -v flatpak >/dev/null 2>&1; then
    HAS_FLATPAK=1
fi

if command -v snap >/dev/null 2>&1; then
    HAS_SNAP=1
fi

# Summary of actions
echo ""
/usr/bin/tput setaf 14
echo "### SYSTEM UPDATE SCRIPT ###"
echo ""
/usr/bin/tput setaf 15
echo "The following actions will be performed:"
echo "- APT package index update"
echo "- Safe system upgrade via aptitude"
echo "- Auto-removal of unused packages"
echo "- Restart services if needed"
[ "$HAS_SNAP" -eq 1 ] && echo "- Snap packages will be refreshed"
[ "$HAS_FLATPAK" -eq 1 ] && {
    echo "- Flatpak packages will be updated"
    echo "- Unused Flatpak packages will be uninstalled"
}
echo "- System firmware will be refreshed and updated"
echo ""

read -rp "Continue with these actions? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborting."
    exit 0
fi

# Begin actions
/usr/bin/tput setaf 10
echo '######## APT UPDATE ########'
/usr/bin/tput setaf 15
/usr/bin/apt update

/usr/bin/tput setaf 10
echo '######## APT UPGRADE ########'
/usr/bin/tput setaf 15
/usr/bin/apt upgrade -y

/usr/bin/tput setaf 10
echo '######## AUTOREMOVE ########'
/usr/bin/tput setaf 15
/usr/bin/apt autoremove --purge -y

/usr/bin/tput setaf 10
echo '######## NEEDRESTART ########'
/usr/bin/tput setaf 15
/usr/sbin/needrestart -r a

if [ "$HAS_SNAP" -eq 1 ]; then
    /usr/bin/tput setaf 10
    echo '######## UPDATE SNAPS ########'
    /usr/bin/tput setaf 15
    /usr/bin/snap refresh
fi

if [ "$HAS_FLATPAK" -eq 1 ]; then
    /usr/bin/tput setaf 10
    echo '######## UPDATE FLATPAKS ########'
    /usr/bin/tput setaf 15
    /usr/bin/flatpak update -y

    /usr/bin/tput setaf 10
    echo '######## UNINSTALL UNUSED FLATPAKS ########'
    /usr/bin/tput setaf 15
    /usr/bin/flatpak uninstall --unused -y
fi

/usr/bin/tput setaf 10
echo '######## UPGRADE FIRMWARE ########'
/usr/bin/tput setaf 15
/usr/bin/fwupdmgr refresh --force
/usr/bin/fwupdmgr get-updates
/usr/bin/fwupdmgr update

/usr/bin/tput setaf 10
echo '################ UPDATES FINISHED ################'
/usr/bin/tput setaf 15
/usr/bin/date

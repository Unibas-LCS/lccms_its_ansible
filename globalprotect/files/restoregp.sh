#!/bin/bash
# This script will attempt to re-install globalprotect on ubuntu 24 so that it will again work.
# The script must be run as root and will require several reboots.

# Check that we are root:
if [ "$EUID" -ne 0 ]
  then echo "Please run as root. Either with sudo or by becoming root (sudo -i)."
  exit
fi

# Check that we are running 24.04
V=`/usr/bin/lsb_release -a | /usr/bin/sed -n '/Release:/ s/Release:[\t ]*//p'`
if [ "$V" != '24.04' ]
then
  echo "This will only apply to Ubuntu 24.04!"
  exit 0
fi

echo "This will attempt to fix a broken resolver when using globalprotect after an upgrade.
Globalprotect will be installed and started, however, a reboot is necesseary to get it all 
correct. The script will reboot when finished.

Press return to continue"
read ignore

# Check that we have the old resolvconf deb file in the current directory:
if [ ! -f resolvconf_1.84ubuntu1_all.deb ]
then
 /usr/bin/wget -q https://lccmsrepo.its.unibas.ch/pool/main/resolvconf_1.84ubuntu1_all.deb
fi
# Check that we have the globalprotect deb file in the current directory:
if [ ! -f GlobalProtect_UI_focal_deb-6.1.3.0-703.deb ]
then
 /usr/bin/wget -q https://lccmsrepo.its.unibas.ch/pool/main/GlobalProtect_UI_focal_deb-6.1.3.0-703.deb
fi

# We will need to have the DNS of ch.archive.ubuntu.com, but the resolver won't work yet.
echo `/usr/bin/dig +short ch.archive.ubuntu.com | /usr/bin/tail -1`	ch.archive.ubuntu.com >>/etc/hosts
echo Set DNS for ch.archive.ubuntu.com

# First we will attempt to stop all globalprotect daemons
/usr/bin/systemctl stop gpd
/usr/bin/systemctl disable gpd
/usr/bin/killall PanGPUI
/usr/bin/killall PanGPS
/usr/bin/killall PanGPA
echo Stopped all globalprotect processes

echo "Will remove the current resolv conf. If there is a question, simply OK it!
Press return to continue"
read ignore

# Completely purge resolvconf of the new Ubuntu 24
/usr/bin/apt purge -y resolvconf
echo Purged current resolvconf

# Register the changes
/usr/bin/systemctl daemon-reload

# Clean up apt
/usr/bin/apt clean

# Now install the old resolvconf
/usr/bin/apt install -y ./resolvconf_1.84ubuntu1_all.deb

# And immediately purge it again as well as purging globalprotect
/usr/bin/apt purge -y resolvconf
/usr/bin/apt purge -y globalprotect
echo Installed then removed old resolvconf and removed global protect

# Clean up apt
/usr/bin/apt clean

# Register the changes
/usr/bin/systemctl daemon-reload

# Install the new resolvconf again
/usr/bin/apt install -y resolvconf
echo Re-installed resolvconf

# Register the changes
/usr/bin/systemctl daemon-reload

# Install global protect.
/usr/bin/apt install -y ./GlobalProtect_UI_focal_deb-6.1.3.0-703.deb

# Remove the old resolvconf package
/usr/bin/rm -f resolvconf_1.84ubuntu1_all.deb GlobalProtect_UI_focal_deb-6.1.3.0-703.deb

# Cleanup /etc/hosts
/usr/bin/sed -i '/ch.archive.ubuntu.com/d' /etc/hosts

/usr/sbin/reboot


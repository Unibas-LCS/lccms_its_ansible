#!/bin/bash
cat <<EOF > /etc/apt/apt.conf.d/dpkg
Dpkg::Options {
   "--force-confdef";
   "--force-confnew";
}
EOF
systemctl mask suspend.target
apt update
apt dist-upgrade -y
apt purge -y resolvconf
do-release-upgrade -q DistUpgradeViewNonInteractive
/usr/.ansible/ansibleRun.sh
rm -f /etc/apt/apt.conf.d/dpkg
systemctl unmask suspend.target

#!/bin/bash
cat <<EOF > /etc/apt/apt.conf.d/dpkg
Dpkg::Options {
   "--force-confdef";
   "--force-confnew";
}
EOF
systemctl mask suspend.target
apt update
if apt dist-upgrade -y; then
   apt purge -y resolvconf
   /usr/bin/do-release-upgrade -q DistUpgradeViewNonInteractive
   OUTPUT=$?
   if [ $OUTPUT -eq 0 ]; then
      /usr/.ansible/ansibleRun.sh
   fi
fi
rm -f /etc/apt/apt.conf.d/dpkg
systemctl unmask suspend.target
exit $OUTPUT

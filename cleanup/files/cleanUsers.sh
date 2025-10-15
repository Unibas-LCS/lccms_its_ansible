#!/bin/bash
#
# This script can be used to clean up the users space before handing out the machine to
# a new lendor.
#

if [ `/usr/bin/id -u` != 0 ]
then
  echo "You must be root to run this script!"
  exit 1
fi

for e in `/usr/bin/ls /home`
do
  if /usr/bin/grep "$e:" /etc/passwd >/dev/null
  then
    # If we have a guest account, clean all data and copy the template.
    if [[ "$e" == "guest" ]]
    then
      /usr/bin/rm -rf /home/guest
      /usr/sbin/mkhomedir_helper guest
      echo "$e reset."
    else
      echo "$e not removed."
    fi
  else
    echo "Removing $e's home."
    /usr/bin/rm -rf /home/$e
  fi
done


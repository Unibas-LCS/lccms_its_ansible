#!/bin/bash
localadmin_exists=`/usr/bin/grep localadmin /etc/passwd`
if [ $? -eq 0 ]; then
	echo $localadmin_exists | /usr/bin/cut -d":" -f3 
	exit 0
fi
uids=`/usr/bin/cut -d":" -f3 /etc/passwd | /usr/bin/sort -rn`
i=999
for u in $uids; do
	if [ $u -le $i ]; then
		if [ $u -lt $i ]; then
      if ! /usr/bin/grep ':'$i':' /etc/group >/dev/null
      then
        echo $i
        exit 0
     fi
		fi
		((i--))
	fi
done
exit 1

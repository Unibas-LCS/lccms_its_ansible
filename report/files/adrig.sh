# Check if admin rights are granted to any user in /home
#!/bin/bash
HOMES=`/bin/ls /home | grep -v localadmin`
for user in $(echo $HOMES)
do
  if [[ `/bin/cat /etc/group | grep sudo | grep $user` ]]; then
          echo "granted"
          exit 0
  fi
done
echo ""

#!/bin/bash
# This script will check for an encrypted disk. If the disk is encrypted, it will  
# return 'active' otherwise 'inactive'

# Step 1: Get the device that contains /home
device=$(/usr/bin/findmnt -n -o SOURCE -T /home)

if [ -z "$device" ]; then
    echo "Error: Could not determine device for /home"
    exit 1
fi

# Step 2: Resolve to full canonical path
device=$(/usr/bin/readlink -f "$device")

# Step 3: Walk all underlying block devices recursively
get_all_underlying_devices() {
    local dev="$1"
    local base=$(/usr/bin/basename "$dev")
    local children

    # If dev is LVM or dm, get its backing device(s)
    children=$(/usr/bin/lsblk -nro NAME,TYPE | /usr/bin/awk -v d="$base" '
        {
            if ($2 == "lvm" || $2 == "crypt" || $2 == "dm") {
                parent[$1] = 1
            } else {
                child[$1] = 1
            }
        }
        END {
            for (c in child) {
                print "/dev/" c
            }
        }
    ' | xargs -n1 /usr/bin/readlink -f | sort -u)

    echo "$children"
}

# Step 4: Collect devices and test for LUKS
for dev in $(get_all_underlying_devices "$device"); do
    if /usr/sbin/cryptsetup isLuks "$dev" 2>/dev/null; then
        echo "encrypted"
        exit 0
    fi
done

echo "not encrypted"

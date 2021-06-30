#!/bin/bash

interface_up_count=$(ip link | awk '/mtu.*state UP/ {print $0}' | wc -l)

if [[ ${interface_up_count} -ge 1 ]]; then
   for i in $(ls -1 /sys/class/net/ | grep -v -E 'lo|bonding' | xargs)
   do
     interface_speed=$(cat /sys/class/net/${i}/speed 2>/dev/null)
     interface_duplex=$(cat /sys/class/net/${i}/duplex 2>/dev/null)
     interface_state=$(cat /sys/class/net/${i}/operstate 2>/dev/null)
     if [[ ${interface_state} != "up" ]]; then
        interface_speed="unknown"
        interface_duplex="unknown"
     fi
     echo "interface: ${i},${interface_state},${interface_speed},${interface_duplex}"
   done
else
  echo "(no interfaces up)"
fi

exit 0

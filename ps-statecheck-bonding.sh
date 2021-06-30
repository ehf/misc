#!/bin/bash

if [[ -d /proc/net/bonding ]];  then
   for i in /proc/net/bonding/*
   do
       interface_bond="$(basename "${i}")"

       for j in $(cat /sys/class/net/${interface_bond}/bonding/slaves)
       do
          interface_bond_member="${j}"
          interface_speed=$(cat /sys/class/net/${j}/speed 2>/dev/null)
          interface_duplex=$(cat /sys/class/net/${j}/duplex 2>/dev/null)
          interface_state=$(cat /sys/class/net/${j}/operstate 2>/dev/null)
          if [[ ${interface_state} != "up" ]]; then
             interface_speed="unknown"
             interface_duplex="unknown"
          fi
          echo "bonded_interface: ${interface_bond},${interface_bond_member},${interface_state},${interface_speed},${interface_duplex}"
       done

   done
else
         echo "(no bonded_interface)"
fi

exit 0

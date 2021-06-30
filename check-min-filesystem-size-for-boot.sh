#!/bin/bash

# example:
## > ./check-min-filesystem-size-for-boot.sh
## OK        /boot available disk space is 108MB and 70MB or greater is needed to complete OS patching
## >
#


filesystem="/boot"
# check if filesystem is mounted
findmnt -krno OPTIONS ${filesystem} >/dev/null 2>&1 || ( printf "${filesystem} is not mounted\n" && exit 1 )

threshold_size_kb=71680
fs_size_kb=$(df -k -P --block-size=1024 ${filesystem} | awk '/[[:digit:]]%/ {print $4}')
message_1="${filesystem} available disk space is $(( ${fs_size_kb}/1024 ))MB"
message_2="$(( ${threshold_size_kb}/1024 ))MB or greater is needed to complete OS patching"
message="${message_1} and ${message_2}"

if [[ ${fs_size_kb} -lt ${threshold_size_kb} ]]; then
   printf "%-10s" "CRITICAL"
   printf "${message}\n"
   exit 1
else
   printf "%-10s" "OK"
   printf "${message}\n"
   exit 0
fi


#--DONE

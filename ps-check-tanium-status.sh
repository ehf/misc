#!/bin/bash

H_NAME=$(cat /proc/sys/kernel/hostname)
U_NAME=$(uname -r)
TAN_PROC_COUNT=$(pgrep -f TaniumClient -l | wc -l)
TAN_DIR_CHECK=$(test -d /opt/Tanium && echo "PRESENT" || echo "NOT_PRESENT")
UPTIME_OUT=$(uptime | xargs | cut -f1 -d"," | tr '[[:blank:]]' '_')

printf "${H_NAME},${U_NAME},${TAN_PROC_COUNT},${TAN_DIR_CHECK},${UPTIME_OUT}\n"

exit 0



### example output
#    h100.d.408.systems,2.6.32-754.41.2.el6.x86_64,18:17:11_up_7_days,19,PRESENT
#    h101.d.408.systems,2.6.32-754.41.2.el6.x86_64,18:17:11_up_7_days,22,PRESENT
#    h102.d.408.systems,2.6.32-754.41.2.el6.x86_64,18:17:11_up_7_days,22,PRESENT
#    h103.d.408.systems,2.6.32-754.41.2.el6.x86_64,18:17:11_up_7_days,21,PRESENT
#    h104.d.408.systems,2.6.32-754.39.1.el6.x86_64,18:17:11_up_155_days,22,PRESENT
#

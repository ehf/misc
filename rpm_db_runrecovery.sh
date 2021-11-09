#!/bin/bash

DATE=$(date +%Y%m%d.%H%M%S)
timeout --signal=9 20s rpm -qa 2>&1 | grep -qE 'DB_RUNRECOVERY: Fatal error, run database recovery'
if [[ $? -eq 0 ]]; then
   fuser -v /var/lib/rpm/__db.[[:digit:]]* 2>&1 | grep -qE [[:alnum:]]
   if [[ $? -eq 1 ]]; then
      mkdir /var/tmp/rpm-db-backup-${DATE}
      mv /var/lib/rpm/__db* /var/tmp/rpm-db-backup-${DATE}
      yum clean all && rpm --rebuilddb
   else
      fuser -v /var/lib/rpm/__db.[[:digit:]]* 2>&1 | tee /var/tmp/rpmdb-fuser-check-${DATE}.log
   fi
else
   printf "DB_RUNRECOVERY error not found. Will not run 'rpm --rebuilddb'.\n"
fi

exit 0

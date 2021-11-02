#!/bin/bash

set -o errexit

DATE=$(date +%Y%m%d.%H%M%S)
h_name=$(cat /proc/sys/kernel/hostname)
p_util='/usr/bin/package-cleanup'
out_log="/var/tmp/package-cleanup.log.${DATE}"

if [[ ! -x ${p_util} ]]; then
   printf "${p_util} utility not found\n"
   exit 1
fi

#
# cleanup old kernels
# 1. keep 2 for hana hosts
#    * assumption is all Hana hosts have hostnames that start with string 'hana'
# 2. everything else, keeps only currently loaded kernel
#    * this can be problem if loaded kernel is older release
#    * we've seen where new kernel is installed, but not loaded/not running
#
if [[ "${h_name}" =~ ^hana.* ]]; then
  kernel_count=2
fi

# echo command ; do not issue command
# remove echo and quotes to issue command
echo "${p_util} -y --oldkernels --count=${kernel_count:-1}  2>&1 | tee ${out_log}"


exit 0


####
## example output: 
## 
## kernel_count=1 on mon11 host
##
# $ cat /proc/sys/kernel/hostname
# host11.a.408.systems
# $ bash ps-kernel-package-cleanup.sh
# /usr/bin/package-cleanup -y --oldkernels --count=1  2>&1 | tee /var/tmp/package-cleanup.log.20211102.091844
# $
####
##
## kernel_count=2 on hana host
##
# $ cat /proc/sys/kernel/hostname
# hanahost11.a.408.systems
# $ bash ps-kernel-package-cleanup.sh
# /usr/bin/package-cleanup -y --oldkernels --count=2  2>&1 | tee /var/tmp/package-cleanup.log.20211102.092014
# $
####
####
####

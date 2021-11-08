#!/bin/bash

# Example: 
# ./ps-kernel-package-cleanup.sh <count_of_kernel_to_keep> 
#
# ./ps-kernel-package-cleanup.sh 2 
#



###set -o errexit

DATE=$(date +%Y%m%d.%H%M%S)
h_name=$(cat /proc/sys/kernel/hostname)
p_util='/usr/bin/package-cleanup'
out_log="/var/tmp/tan-package-cleanup.log.${DATE}"
kernel_count="$1"

# check package-cleanup is installed
if [[ ! -x ${p_util} ]]; then
   printf "${p_util} utility not found\n"
   exit 1
fi

# check kernel_count is a number
echo "${kernel_count}" | grep -qE '^[0-9]+$'
if [[ $? -eq 0 ]]; then
    printf "${kernel_count} is valid number.\n"
else
    printf "Error: ${kernel_count} is not a number.\n"
    exit 1
fi



# cleanup old kernels
${p_util} -y --oldkernels --count=${kernel_count:-1}  2>&1 | tee ${out_log}


exit 0

#!/bin/bash

timeout --signal=9 10s rpm --quiet -q kernel
if [[ $? -eq 0 ]]; then
   rpm -q kernel | wc -l
else
   ls -1 /boot/initramfs-*.x86_64.img | wc -l
fi

exit 0

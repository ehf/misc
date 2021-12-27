#!/bin/bash

err() {
   printf "error: %s\n" "$@" >&2
}

anaks="/root/anaconda-ks.cfg"
if [[ -s ${anaks} ]]; then
   /usr/bin/stat -c "%n,%y,%z,%x" ${anaks}
else
   err "${anaks} not present"
   exit 1
fi

exit 0

###

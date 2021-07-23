#!/bin/bash

DSA_COMM='/opt/ds_agent/sendCommand'

if [[ ! -x ${DSA_COMM} ]]; then
  printf "${DSA_COMM} utility not found\n"
  exit 1
fi

ds_agent_out=$(${DSA_COMM} --get GetConfiguration | awk '/<SecurityProfile/ { print substr($0,3,length($0)-3) }')

if [[ -z "${ds_agent_out}" ]]; then
  printf "GetConfiguration did return any SecurityProfile information\n"
  exit 1
else
  echo "${ds_agent_out}" | xargs -n 1 | sort -V | xargs
fi

exit 0


#!/bin/bash

list_to_check=$1
mdb_path="/usr/local/mdb/"


err() {
   printf "error: %s\n" "$@" >&2
}

print_usage() {
   printf "Usage: $0 <file-with-IPs>\n"
}

if [[ $# -lt 1 ]] || [[ $# -gt 1 ]]; then
   err "incorrect number of arguments."
   print_usage
   exit 1
fi

validate_ip() {
   local ipaddr=$1

   echo "${ipaddr}" | grep -q "[[:alpha:]]"
   if [[ $? -eq 0 ]];then
      continue
   fi
   
   if [[ ${ipaddr} =~ ^[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}$ ]]; then
      OIFS=$IFS
      IFS='.'
      ip=( ${ipaddr} )
      IFS=$OIFS
      if [[ ${ip[0]} -le 255 ]] && [[ ${ip[1]} -le 255 ]] && \
         [[ ${ip[2]} -le 255 ]] && [[ ${ip[3]} -le 255 ]]; then
         return 0
      else
         return 1
      fi
   fi
}

check_file() {
   local ipaddr=$1
   file_to_check=$(grep -r -w -F ${ipaddr} ${mdb_path} 2>&1 | awk -F\: '{ print $1 }')
}

output_match() {
   printf "${i},$file_to_check,"
   awk -F\: '/^status/ { print $2 }' ${file_to_check} | xargs
}


for i in $(cat ${list_to_check})
do
   validate_ip $i
   if [[ $? -eq 0 ]]; then
      check_file $i
      if [[ -s ${file_to_check} ]];then
         output_match
      fi
   fi
done

exit 0

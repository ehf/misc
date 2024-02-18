#!/usr/bin/env bash

# ehf

while getopts c:f: flag
do
  case "${flag}" in
    c)
        if [[ "${OPTARG}" = "one" ]]; then
            checkme=("us-west-1" "us-west-2")
        elif [[ "${OPTARG}" = "two" ]]; then
            checkme=("us-east-1" "us-east-2")
        else
            checkme=("us-west-1" "us-west-2")
        fi
        ;;
    f)
        file="${OPTARG}"
        ;;
  esac
done


for i in ${checkme[@]}
do
    aws ec2 describe-network-interfaces \
        --region ${i} \
        --query "NetworkInterfaces[*].[PrivateIpAddress,Description]" \
        --output=text | grep -w -f ${file}
done | sort -V

#--DONE

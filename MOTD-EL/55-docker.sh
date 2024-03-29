#!/bin/bash

if [ "Z$(ps o comm="" -p $(ps o ppid="" -p $$))" == "Zcron" -o \
     "Z$(ps o comm="" -p $(ps o ppid="" -p $(ps o ppid="" -p $$)))" == "Zcron" ]
then
    :
else
if [ -e /usr/bin/docker ]
then
    if [ -r /var/run/docker.sock ]
    then
# set column width
COLUMNS=2
# colors
green="\e[1;32m"
red="\e[1;31m"
undim="\e[0m"

mapfile -t containers < <(docker ps -a --format '{{.Names}}\t{{.Status}}' | sort -k1 | awk '{ print $1,$2 }')

out=""
for i in "${!containers[@]}"; do
    IFS=" " read name status <<< ${containers[i]}
    # color green if service is active, else red
    if [[ "${status}" == "Up" ]]; then
        out+="${name}:,${green}${status,,}${undim},"
    else
        out+="${name}:,${red}${status,,}${undim},"
    fi
    # insert \n every $COLUMNS column
    if [ $((($i+1) % $COLUMNS)) -eq 0 ]; then
        out+="\n"
    fi
done
out+="\n"

printf "\ndocker status:\n"
printf "$out" | column -ts $',' | sed -e 's/^/  /'
    fi
fi
fi
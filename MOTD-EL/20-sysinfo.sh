#!/bin/bash

if [ "Z$(ps o comm="" -p $(ps o ppid="" -p $$))" == "Zcron" -o \
     "Z$(ps o comm="" -p $(ps o ppid="" -p $(ps o ppid="" -p $$)))" == "Zcron" ]
then
    :
else
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# get load averages
IFS=" " read LOAD1 LOAD5 LOAD15 <<<$(cat /proc/loadavg | awk '{ print $1,$2,$3 }')
# get free memory
IFS=" " read USED AVAIL TOTAL <<<$(free -htm | grep "Mem" | awk {'print $3,$7,$2'})
# get processes
PROCESS=`ps -eo user=|sort|uniq -c | awk '{ print $2 " " $1 }'`
PROCESS_ALL=`echo "$PROCESS"| awk {'print $2'} | awk '{ SUM += $1} END { print SUM }'`
PROCESS_ROOT=`echo "$PROCESS"| grep root | awk {'print $2'}`
PROCESS_USER=`echo "$PROCESS"| grep -v root | awk {'print $2'} | awk '{ SUM += $1} END { print SUM }'`
# get processors
PROCESSOR_NAME=`grep "model name" /proc/cpuinfo | cut -d ' ' -f3- | awk {'print $0'} | head -1`
PROCESSOR_COUNT=`grep -ioP 'processor\t:' /proc/cpuinfo | wc -l`

W="\e[0;39m"
G="\e[1;32m"
Y="\e[38;5;214m"
ipext=$(curl -s https://ipecho.net/plain)
netdev=$(/usr/sbin/ip -o link show | awk -F': ' '{print $2" "}' | tr -d '\n')

echo -e "
${W}system info:
$W  Distro......: $Y`cat /etc/*release | grep "PRETTY_NAME" | cut -d "=" -f 2- | sed 's/"//g'`
$W  Kernel......: $W`uname -sr`

$W  Uptime......: $W`uptime -p`
$W  Load........: $G$LOAD1$W (1m), $G$LOAD5$W (5m), $G$LOAD15$W (15m)
$W  Processes...:$W $G$PROCESS_ROOT$W (root), $G$PROCESS_USER$W (user), $G$PROCESS_ALL$W (total)

$W  CPU.........: $W$PROCESSOR_NAME ($G$PROCESSOR_COUNT$W vCPU)
$W  Memory......: $G$USED$W used, $G$AVAIL$W avail, $G$TOTAL$W total$W

$W  Local IP....: $W`hostname -I`
$W  External IP.: $W$ipext
$W  Net devices.: $W$netdev"
fi

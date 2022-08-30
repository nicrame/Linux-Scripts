#!/bin/bash

if [ "Z$(ps o comm="" -p $(ps o ppid="" -p $$))" == "Zcron" -o \
     "Z$(ps o comm="" -p $(ps o ppid="" -p $(ps o ppid="" -p $$)))" == "Zcron" ]
then
    :
else
system=$(hostname)
echo "
SysOP: root@$system
" | lolcat -f
unset LC_ALL
fi
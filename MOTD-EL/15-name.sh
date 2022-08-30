#!/bin/bash

if [ "Z$(ps o comm="" -p $(ps o ppid="" -p $$))" == "Zcron" -o \
     "Z$(ps o comm="" -p $(ps o ppid="" -p $(ps o ppid="" -p $$)))" == "Zcron" ]
then
    :
else
/usr/bin/env figlet "$(hostname)" | /usr/bin/env lolcat -f
fi
#!/bin/bash

if [ "Z$(ps o comm="" -p $(ps o ppid="" -p $$))" == "Zcron" -o \
     "Z$(ps o comm="" -p $(ps o ppid="" -p $(ps o ppid="" -p $$)))" == "Zcron" ]
then
    :
else
export LC_ALL=C
user="$(whoami)"
echo "- -- -- ------ Audaces Fortuna Iuvat  ------ -- -- -" | lolcat -f
echo -e "Welcome \e[38;5;214m$user \e[39;0mat:"
fi
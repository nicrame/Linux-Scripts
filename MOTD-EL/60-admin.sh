#!/bin/bash
system=$(hostname)
echo "
SysOP: root@$system
" | lolcat -f
unset LC_ALL

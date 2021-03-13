#!/bin/bash

if [ -e /var/log/fail2ban.log ]
then
logfile='/var/log/fail2ban.log*'
mapfile -t lines < <(grep -hioP '(\[[a-z-]+\]) ?(?:restore)? (ban|unban)' $logfile | sort | uniq -c)
jails=($(printf -- '%s\n' "${lines[@]}" | grep -oP '\[\K[^\]]+' | sort | uniq))

out=""
for jail in ${jails[@]}; do
    bans=$(printf -- '%s\n' "${lines[@]}" | grep -iP "[[:digit:]]+ \[$jail\] ban" | awk '{print $1}')
    restores=$(printf -- '%s\n' "${lines[@]}" | grep -iP "[[:digit:]]+ \[$jail\] restore ban" | awk '{print $1}')
    unbans=$(printf -- '%s\n' "${lines[@]}" | grep -iP "[[:digit:]]+ \[$jail\] unban" | awk '{print $1}')
    bans=${bans:-0} # default value
    restores=${restores:-0} # default value
    unbans=${unbans:-0} # default value
    bans=$(($bans+$restores))
    diff=$(($bans-$unbans))
    out+=$(printf "$jail, %+3s bans, %+3s unbans, %+3s active" $bans $unbans $diff)"\n"
done

printf "\nfail2ban status (monthly):\n"
printf "$out" | column -ts $',' | sed -e 's/^/  /'
fi

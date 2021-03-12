#!/bin/bash

# set column width
COLUMNS=3
# colors
green="\e[1;32m"
red="\e[1;31m"
undim="\e[0m"

services=("nginx" "httpd" "mariadb" "php74-php-fpm" "php80-php-fpm" "php-fpm" "named" "sshd" "smb" "nmb" "smartd" "postfix" "dovecot" "fail2ban" "pure-ftpd" "urbackup-server" "urbackupclientbackend" "docker")
# sort services
IFS=$'\n' services=($(sort <<<"${services[*]}"))
unset IFS

service_status=()
# get status of all services
for service in "${services[@]}"; do
    service_status+=($(systemctl is-active "$service"))
done

out=""
for i in ${!services[@]}; do
    # color green if service is active, else red
    if [[ "${service_status[$i]}" == "active" ]]; then
        out+="${services[$i]}:,${green}${service_status[$i]}${undim},"
    else
        out+="${services[$i]}:,${red}${service_status[$i]}${undim},"
    fi
    # insert \n every $COLUMNS column
    if [ $((($i+1) % $COLUMNS)) -eq 0 ]; then
        out+="\n"
    fi
done
out+="\n"

printf "\nservices:\n"
printf "$out" | column -ts $',' | sed -e 's/^/  /'

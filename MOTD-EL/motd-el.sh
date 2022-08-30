#!/bin/bash

# #### MOTD scripts for EL
# Version 1.6
# Testes on: CentOS 7/8, RHEL 8, Debian 11
#
# This will install colorful and nice motd (message of the day) with some system informations.    
# MOTD is generated with scripts, that will be extracted to /etc/profile.d  
# where you may modify them to suite your needs.  
# You may call this script with administrator email as argument: ./motd-el.sh admin@email.com  
#
# Most of the work is done using scripts made and published here: https://github.com/yboetz/motd  
#
# More info:  
# [PL/ENG] https://www.marcinwilk.eu/en/projects/motd-dla-el/
#
# Feel free to contact me: marcin@marcinwilk.eu  
# www.marcinwilk.eu  
# Marcin Wilk  
#
# License:
# 1. You use it at your own risk. Author is not responsible for any damage made with that script.  
# 2. Feel free to share and modify this as you like.  
#
# Changelog: 
# v 1.6 - 30.08.2022  
# Detecting if running from cron job, and then skip any operation (so it will not mess cron logs).
# Download script files from GitHub instead of extracting from script file.
# Checking if running user is root.
# v 1.5 - 08.06.2022  
# Add Debian 11 support.
# Ingore user locale settings that may broke output.
# v 1.4 - 15.03.2021  
# Add full file path for last command so it will work when sudo is used.  
# Fix for correct EPEL repo installing on EL7.  
# v 1.3 - 13.03.2021  
# Add monthly stats of fail2ban script.  
# Add docker containers list script.  
# Changed some colors to work better on white background.  
# Show more information while processing installer and system operator argument support.  
# v 1.2 - 12.03.2021  
# Small fixes.  
# v 1.1 - 12.03.2021  
# First release, tested on CentOS 7.  
# v 1.0 - 11.03.2021  
# Play at home, tested on RHEL 8 and CentOS 8.  

user=$( whoami )
# User name that run the script. No reasons to change it.
# Used only for testing.

if [ $user != root ]
then
    echo "You must be root. Mission aborted!"
    echo "You are trying to start this script as: $user"
    exit 0
fi

# Installing packages that are need to make world colorful and nice!
echo -e "\e[38;5;214mMOTD for EL will make world colorful and nice!\e[39;0m"
echo ""
if [ $# -eq 0 ]
then
	echo "You may call this script with administrator email as argument: ./motd-el.sh admin@email.com"
fi
echo "Adding colors to the system started!"
echo "Updating system packages. It may take some time, be patient!"
if [ -e /etc/redhat-release ]
then
	yum update -y -q
	echo "Installing unzip and dnf."
	yum -y -q install dnf unzip wget
	echo "Enabling EPEL repo."
	yum -y -q install epel-release
	echo "Installing figlet and ruby packages."
	dnf -y -q install figlet ruby
else
	echo "No EL detected, trying Debian...."
	if [ -e /etc/debian_version ]
	then
		apt install -y -qq lolcat figlet ruby wget unzip > /dev/null
	else
		echo "Debian is not detected either, exiting..."
		exit 0
	fi
fi

if [ -e /etc/redhat-release ]
then
	if [ -e /usr/local/bin/lolcat ]
	then
		echo "Lolcat already installed, skipping..."
	else
		echo "Installing lolcat from sources."
		cd /tmp
		wget https://github.com/busyloop/lolcat/archive/master.zip
		unzip master.zip
		rm -rf master.zip
		cd lolcat-master/bin
		gem install lolcat
		cd /tmp
		rm -rf lolcast-master
	fi
else
	echo "Skipping lolcat compiling from sources (already installed)."
fi

echo ""
echo "Downloading script files to /etc/prfile.d/."
cd /etc/profile.d/
wget -q https://github.com/nicrame/Linux-Scripts/raw/master/MOTD-EL/10-banner.sh
wget -q https://github.com/nicrame/Linux-Scripts/raw/master/MOTD-EL/15-name.sh
wget -q https://github.com/nicrame/Linux-Scripts/raw/master/MOTD-EL/20-sysinfo.sh
wget -q https://github.com/nicrame/Linux-Scripts/raw/master/MOTD-EL/35-diskspace.sh 
wget -q https://github.com/nicrame/Linux-Scripts/raw/master/MOTD-EL/40-services.sh
wget -q https://github.com/nicrame/Linux-Scripts/raw/master/MOTD-EL/50-fail2ban.sh
wget -q https://github.com/nicrame/Linux-Scripts/raw/master/MOTD-EL/55-docker.sh
wget -q https://github.com/nicrame/Linux-Scripts/raw/master/MOTD-EL/60-admin.sh

if [ $# -eq 0 ]
then
	:
else
	sed -i 's/\SysOP: root@$system\b/SysOP: $1/g' /etc/profile.d/60-admin.sh
fi

if [ -e /etc/debian_version ]
then
	sed -i 's/\blolcat -f\b/\/usr\/games\/lolcat -f/g' /etc/profile.d/10-banner.sh
	sed -i 's/\blolcat -f\b/\/usr\/games\/lolcat -f/g' /etc/profile.d/15-name.sh
	sed -i 's/\bhttpd\b/apache2/g' /etc/profile.d/40-services.sh
	if [ -e /etc/init.d/pure-ftpd-mysql ]
	then
		sed -i 's/\bpure-ftpd\b/pure-ftpd-mysql/g' /etc/profile.d/40-services.sh
	fi
	sed -i 's/\bphp80-php-fpm\b/php7.4-fpm/g' /etc/profile.d/40-services.sh
	sed -i 's/\bphp74-php-fpm\b/rspamd/g' /etc/profile.d/40-services.sh
	sed -i 's/\bphp-fpm\b/postgrey/g' /etc/profile.d/40-services.sh
	sed -i 's/\blolcat -f\b/\/usr\/games\/lolcat -f/g' /etc/profile.d/60-admin.sh
fi

if [ -e /etc/redhat-release ]
then
	echo "Everything is ready. Have fun!" | /usr/local/bin/lolcat -f
else
	echo "Everything is ready. Have fun!" | /usr/games/lolcat -f
fi

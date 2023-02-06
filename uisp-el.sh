#!/bin/bash

# UISP formerlny known as Ubiquiti Network Management System (UNMS) install script for EL8/9 variants (CentOS, RockyLinux, RHEL).
# It will also start installer on Debian Linux.
# Version 1.4
#
# This script is made to install UISP on EL8 and EL9 (clear minimal OS install) with disabled web servers (like httpd or nginx).
# Also if You got docker installed, it will remove it and install current Docker CE version and composer.
# Please check this file before use, you may unhash some options.
# You use it at your own risk!
#
# More info:
# [PL] https://www.marcinwilk.eu/pl/projects/unms-install-on-centos-8-linux/
# [EMG] https://www.marcinwilk.eu/en/projects/unms-install-on-centos-8-linux/
#
# Feel free to contact me: marcin@marcinwilk.eu
# www.marcinwilk.eu
# Marcin Wilk
#
# License:
# 1. You use it at your own risk. Author is not responsible for any damage made with that script.
# 2. Any changes of scripts must be shared with author with authorization to implement them and share.
#
# Changelog:
# v 1.5 - 06.02.2023
# Changed the way ulimits are configured from UISP files, to docker service configuration. It's much more clean now and better for updates of UISP.
# v 1.4 - 05.02.2023
# Found fix for starting up on on EL9 / Stream distributions - rabbit-mq container had too high open files limit (ulimit -n 1073741816).
# Revert SELinux change to not disabled.
# Tested on RockyLinux 9, RockyLinux 8 and CentOS Stream 9.
# v 1.3.2 - 03.02.2023
# Just small tweaks.
# Disabling SELinux on Stream distros.
# Add some more infos.
# v 1.3 - 01.02.2023
# Added support for EL9
# Added fallback for Debian installer if that OS is detected.
# Tested on RockyLinux 9, RHEL 9 and RockyLinux 8.
# Use Docker Compose from repo (so it will autoupdate correctly now with dnf update).
# v 1.2.1 - 05.08.2021
# Use Docker Compose v 1.29.2.
# Tested (and working) on Rocky Linux 8.4.
# v 1.2 - 02.03.2021
# Added --allowerasing flag for installing docker (it resolved problems on test env). This will disable cockpit!
# Firewall rules fixes.
# Tested on CentOS 8.3 and RHEL 8.3.
# v 1.1 - 29.08.2020
# First public release.
# Added yes to not ask when UNMS detect unsupported Linux distro.
# v 1.0 - 28.08.2020
# First version.

# Disabling SELinux if problems occurs (EL8):
# sudo sed --in-place=.bak 's/^SELINUX\=enforcing/SELINUX\=permissive/g' /etc/selinux/config

addr=$( hostname -I )

export LC_ALL=C
if [ -e /etc/redhat-release ]
then
	echo "Reading OS and version:"
	cat /etc/redhat-release
else
	echo "No EL detected, trying Debian...."
	if [ -e /etc/debian_version ]
	then
		echo "Running official installer procedure for Debian OS..."
		curl -fsSL https://uisp.ui.com/v1/install > /tmp/uisp_inst.sh && sudo bash /tmp/uisp_inst.sh --unattended
		exit 0
	else
		echo "Debian is not detected either, exiting..."
		exit 0
	fi
fi

el5=$( cat /etc/redhat-release | grep "release 5" )
el6=$( cat /etc/redhat-release | grep "release 6" )
el7=$( cat /etc/redhat-release | grep "release 7" )
el8=$( cat /etc/redhat-release | grep "release 8" )
el9=$( cat /etc/redhat-release | grep "release 9" )
str=$( cat /etc/redhat-release | grep "Stream" )

if [ -n "$el5" ] || [ -n "$el6" ] || [ -n "$el7" ]
then
	echo "Too old EL version. Pleasu upgrade to EL 8 or 9."
	echo "Mission aborted!."
	exit 0
fi

#if [ -n "$str" ]
#then
# 	echo "DISABLING SELinux for Stream edition."
# 	setenforce 0
# 	grubby --update-kernel ALL --args selinux=0 
#fi

if [ -n "$el9" ] || [ -n "$el8" ]
then
	echo "Updating and installing additional packages. Some may be removed before reinstalling."
	# Updating OS, removing current Docker install files and installing needed packages:
	sudo dnf update -y --quiet
	sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine --quiet
	sudo dnf install -y device-mapper device-mapper-persistent-data device-mapper-event device-mapper-libs device-mapper-event-libs lvm2 curl net-tools wget --quiet

	# Installing Docker CE with Composer:
	sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo --quiet
	sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin --allowerasing --nobest --quiet
	sudo systemctl enable --now docker
	sudo systemctl enable --now containerd
	sudo usermod -aG docker $USER

	# Opening Firewall ports:
	# Noticed that are opened, but Ubi do not say to open them:
	# sudo firewall-cmd --zone=public --add-port=24224/tcp --permanent
	# sudo firewall-cmd --zone=public --add-port=5140/tcp --permanent
	
	# Ports used only when using Reverse Proxy
	# sudo firewall-cmd --zone=public --add-port=8443/tcp --permanent
	# sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent
	
	echo "Configuring firewall."
	sudo firewall-cmd --zone=public --add-port=9000/tcp --permanent
	sudo firewall-cmd --zone=public --add-port=2055/udp --permanent
	sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
	sudo firewall-cmd --zone=public --add-port=81/tcp --permanent
	sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
	sudo firewall-cmd --zone=public --add-port=22/tcp --permanent
	sudo firewall-cmd --reload
	
	if [ -n "$el9" ]
	then
		echo "Configurind docker service for EL9/Stream distros to work correctly with UISP."
		sudo sed -i 's/containerd.sock/& --default-ulimit nofile=1048576:1048576/' /usr/lib/systemd/system/docker.service
		sudo systemctl daemon-reload
		sudo systemctl restart docker
	fi
	
	# Installing UISP/UNMS:
	sudo curl -fsSL https://uisp.ui.com/v1/install > /tmp/uisp_inst.sh && sudo bash /tmp/uisp_inst.sh --unattended
	
	# Adding Docker netowrk interfaces to trusted zone in firewall:
	sudo ip -o link show | awk -F': ' '{if ($2 ~/^br/) {print $2}}' >> brfaces.txt
	sudo xargs -I {} -n 1 firewall-cmd --permanent --zone=docker --change-interface={} < brfaces.txt
	# sudo firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 4 -i docker0 -j ACCEPT
	sudo firewall-cmd --reload
	sudo rm -rf brfaces.txt
	echo "Waiting for UISP to preconfigure itself, two minutes please."
	sleep 121
fi

echo "Now it is possible to login using this computer hostname/ip in web browser.
But give it few minutes before try, it take time for first run.
Here is Your computer IP to use to connect with UISP:
https://$addr
"
unset LC_ALL
exit 0

#!/bin/bash

# UISP formerlny known as Ubiquiti Network Management System (UNMS) install script for EL8 variants (CentOS, RockyLinux, RHEL).
# Version 1.2
#
# This script is made for clear CentOS 8 installed, with disabled web servers (like httpd or nginx).
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
# v 1.2 - 02.03.2021
# Added --allowerasing flag for installing docker (it resolved problems on test env). This will disable cockpit!
# Firewall rules fixes.
# Tested on CentOS 8.3 and RHEL 8.3.
# v 1.1 - 29.08.2020
# First public release.
# Added yes to not ask when UNMS detect unsupported Linux distro.
# v 1.0 - 28.08.2020
# First version.

# Disabling SELinux if problems occurs:
# sudo sed --in-place=.bak 's/^SELINUX\=enforcing/SELINUX\=permissive/g' /etc/selinux/config

# Updating OS, removing current Docker install files and installing needed packages:
sudo dnf update -y
sudo dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
sudo dnf install -y device-mapper device-mapper-persistent-data device-mapper-event device-mapper-libs device-mapper-event-libs lvm2 curl

# Installing Docker CE with Composer:
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce --allowerasing --nobest
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Opening Firewall ports:
# Noticed that are opened, but Ubi do not say to open them:
# sudo firewall-cmd --zone=public --add-port=24224/tcp --permanent
# sudo firewall-cmd --zone=public --add-port=5140/tcp --permanent
# sudo firewall-cmd --zone=public --add-port=9000/tcp --permanent

# Ports used only when using Reverse Proxy
# sudo firewall-cmd --zone=public --add-port=8443/tcp --permanent
# sudo firewall-cmd --zone=public --add-port=8080/tcp --permanent

sudo firewall-cmd --zone=public --add-port=2055/udp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=81/tcp --permanent
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --reload

# Installing UNMS:
sudo curl -fsSL https://unms.com/v1/install > /tmp/unms_inst.sh && sudo yes | bash /tmp/unms_inst.sh --unattended

# Adding Docker netowrk interfaces to trusted zone in firewall:
sudo ip -o link show | awk -F': ' '{if ($2 ~/^br/) {print $2}}' >> brfaces.txt
sudo xargs -I {} -n 1 firewall-cmd --permanent --zone=docker --change-interface={} < brfaces.txt
# sudo firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 4 -i docker0 -j ACCEPT
sudo firewall-cmd --reload
sudo rm -rf brfaces.txt

# Restarting docker:
sudo systemctl restart docker

# Now it is possible to login using this computer hostname/ip in web browser.

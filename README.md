# Linux-Scripts
This is place for scripts that i made to help in installation or configuration of software on GNU/Linux (usually CentOS or Scientific Linux). Most of them are made because there was lack of some solution over the Internet.

Try to look inside script before use, there are some things to setup or configure that may interests you.

License:
1. You use it at your own risk. Author is not responsible for any damage made with that script.
2. Any changes of scripts must be shared with author with authorization to implement them and share.

make-kiosk.sh - Scientific Linux/CentOS (versions 5 to 7) KIOSK generator
It will make Your computer start directly to web browser with preconfigured URL, and will clean web history and settings after reboot.

More info: https://www.marcinwilk.eu/en/projects/scientific-linux-and-centos-kiosk/

crtchk.sh - Pure-FTPd + Let’s Encrypt
It make Pure-FTPd server to work with certificates signed with Let’s Encrypt. The script compares the currently used Let’s Encrypt certificate with the one used by the FTP server. If it detects changes, the script creates a new file compatible with Pure-FTPd. Script should work in the cron and check certificates periodically.

More info: https://www.marcinwilk.eu/en/projects/pure-ftpd-lets-encrypt/

make-kodi.sh - HTPC on CentOS 8 Linux with KODI
Script that automates the installation and configuration of CentOS 8 Linux with KODI (formerly XBMC) under HTPC (a computer for media playback). It will make Your computer starts directly to KODI after reboot. It use flatpak package by default, but You may configure it to use sources if you prefer.

More info: https://www.marcinwilk.eu/en/projects/htpc-on-centos-8-linux-with-kodi/

unms-centos.sh - UNMS installation script for CentOS 8 Linux
This takes the appropriate steps to install and run UNMS in CentOS 8 Linux. It was prepared for clear CentOS 8 install.

More info: https://www.marcinwilk.eu/en/projects/unms-install-on-centos-8-linux/

Feel free to contact me: marcin@marcinwilk.eu

https://www.marcinwilk.eu/

Marcin Wilk

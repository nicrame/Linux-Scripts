#!/bin/bash

# Nextcloud Install Script
# Made for freshly installed, server Linux distributions using AMD64(x86_64) architecture: 
# Debian (11,12), Enterprise Linux (9), Ubuntu Server (22), Fedora Server (39).
#
# It will update OS, preconfigure everything, install neeeded packages and Nextcloud.
# There is also support for upgrading Nextcloud and OS packages (just download and run latest version of this script).
# 
# This Nextcloud installer allows it working locally and thru Internet: 
# - local IP address with and without SSL (it use self signed SSL certificate for https protocol),
# - using domain name (local and over Internet), if domain is already configured correctly (it will use free Let's Encrypt service for certificate signing). 
# Used software packages are Apache (web server), MariaDB (database server), PHP 8.2 (programming language with interpreter), 
# NTP (time synchronization service), and Redis (cache server) installed and used.
# Some other software is also installed for better preview/thumbnails generation by Nextcloud like LibreOffice, Krita, ImageMagick etc.
# Also new service for Nextcloud cron is generated that starts every 5 minutes so Nextcloud can dos ome work while users are not connected.
#
# To use it just use this command:
# sudo sh -c "wget -q https://github.com/nicrame/Linux-Scripts/raw/master/nextcloud-ins.sh && chmod +x nextcloud-ins.sh && ./nextcloud-ins.sh"
# 
# You may also add specific variables (lang, mail, dns) that will be used, by adding them to command above, e.g:
# sudo sh -c "wget -q https://github.com/nicrame/Linux-Scripts/raw/master/nextcloud-ins.sh && chmod +x nextcloud-ins.sh && ./nextcloud-ins.sh -lang=pl -mail=my@email.com -dm=domain.com -nv=24 -fdir=/mnt/sdc5/nextcloud-data"
# -lang (for language) variable will install additional packages specific for choosed language and setup Nextcloud default language.
# Currently supported languages are: none (default value is none/empty that will use web browser language), Arabic (ar), Chinese (zh), French (fr), Hindi (hi), Polish (pl), Spanish (es) and Ukrainian (uk),
# -mail variable is for information about Your email address, that will be presented to let's encrypt, so you'll be informed if domain name SSL certificate couldn't be refreshed (default value is empty),
# -dm variable is used when you got (already prepared and configured) domain name, it will be configured for Nextcloud server and Let's encrypt SSL (default value is empty),
# -nv variable allows You to choose older version to install, supported version are: 24-28, empty (it will install newest, currently v28),
# -fdir variable gives possibility to specify where user files and nextcloud.log files are stored, by default this settings will leave default location that is /var/www/nextcloud/data.
# selecting different location will not change Nextcloud configuration, but will bind (using mount) default Nextcloud location, to the specified one,
# so using security mechanism like chroot/jail/SELinux etc. will work correctly without additional configuration for them, web server etc.
# For example if option -fdir=/mnt/sdc5/nextcloud-data will be used, then entering directory /var/www/nextcloud/data will actually show content of /mnt/sdc5/nextcloud-data.
# If you want to use spaces between words in directory name, then put path inside double quotes, eg. -fdir="/mnt/sdx/users data folder"
# To remember data directory settings, and mount them each OS start /etc/fstab file is modified.
# 
# You may start the script again, so it will upgrade OS packages and Nextcloud to newer versions.
#
# After install You may use Your web browser to access Nextcloud using local IP address,
# or domain name, if You have configured it before (DNS setting, router configuration should be done earlier by You). 
# Both HTTP and HTTPS protocols are enabled by default (localhost certificate is generated
# by default, and domain certificate with Let's encrypt if You use add it as command variable).
#
# It was tested with many Nextcloud versions since v24.
# 
# In case of problems, LOG output is generated at /var/log/nextcloud-installer.log.
# Attach it if You want to report errors.
#
# More info:
# [PL/ENG] https://www.marcinwilk.eu/pl/projects/linux-scripts/nextcloud-debian-install/
#
# Feel free to contact me: marcin@marcinwilk.eu
# www.marcinwilk.eu
# Marcin Wilk
#
# License:
# 1. You use it at your own risk. Author is not responsible for any damage made with that script.
# 2. Any changes of scripts must be shared with author with authorization to implement them and share.
#
# V 1.10 - 19.04.2024
# - Nextcloud Hub 8 (v29) is now default/latest
# - PHP 8.3 is used as default PHP version
# - Fixed error that didn't allow installing older versions of NC (and PHP 7.4)
# V 1.9.2 - 13.03.2024
# - checking if "fdir" parameter is configured for already existing directory and inform if not
# - fix spaces in directory names saved in fstab, configured with -fdir argument (fstab do not support spaces in directory names)
# V 1.9.1 - 12.03.2024
# - some description update, and few code changes that do not affect the way script is working
# - add PHP 8.3 install code (currently disabled) for future NC versions
# V 1.9 - 04.03.2024
# - new argument that allow to configure location of "data" directory, where user files are stored (it use mount/fstab for security mechanisms compatibility)
# V 1.8.1 - 07.02.2024
# - first release with Fedora Server 39, and Ubuntu Server LTS (22) distributions support
# V 1.8 - 04.02.2024
# - first release with Rocky Linux (9), and other Enterprise Linux distributions support
# - a little more code optimizations
# V 1.7.1 - 01.02.2024
# - code cleanup
# - add maintenance window start time configuration (for 28.0.2 released today)
# V 1.7 - 30.01.2024
# - tweaks for thumbnails/preview generation
# - disabe sleep/hibernate modes in OS
# - add HTTP2 protocol support
# - small security fix
# - description improvements
# - packages installer will now wait for background jobs (started by OS) to finish
# V 1.6.4 - 04.01.2024
# - add bz2 module for PHP (for Nextcloud Hub 7)
# - Happy New Year!
# V 1.6.3 - 04.11.2023
# - more tests and fixes
# V 1.6.2 - 04.08.2023
# - few more languages are now supported with -lang= parameter (Arabic (ar), Chinese (zh), French (fr), Hindi (hi), Polish (pl), Spanish (es) and Ukrainian (uk))
# V 1.6.1 - 03.08.2023
# - small tweaks
# V 1.6 - 03.08.2023
# - new variable that allows installing older version of Nextcloud (users reported problems with NC27)
# - the script rename itself after finished work (so installer command always refer to newest version)
# - script is prepared now for few future updates (up to Nextcloud v28)
# V 1.5.5 - 12.07.2023
# - better description of variables use on error
# V 1.5.4 - 07.07.2023
# - fixed some logical problem
# - add support for Debian 12
# - add support for Nextcloud Hub 5 (v27)
# V 1.5.3 - 15.04.2023
# - using older PHP (8.1) version for upgrade process before removing it (Nextcloud do not finish upgrade process on never PHP version)
# - check for currently installed Nextcloud version and update it so many times it needs (till version 26) - when upgrading from script version 1.4 or older
# V 1.5.2 - 05.04.2023
# - twofactor_webauthn app installing and enabling for more security (tested with Yubikey)
# V 1.5.1 - 05.04.2023
# - upgrading from 1.4 and lower added to the script
# V 1.5 - 25.03.2023
# - use Nextcloud Hub 4 (v26)
# - enable opcache again (it looks it's working fine now)
# - use PHP version 8.2
# - install ddclient (dynamic DNS client - https://ddclient.net/)
# - install miniupnpc ans start it for port 80 and 443 to open ports (it should be unncessary)
# - added more variables to use (language, e_mail)
# - installer is now creating file with it's version number for future upgrades
# - installer detects if older versions of script were used, and in the next release it will upgrade everything (nextcloud included)
# V 1.4.3 - 24.02.2023
# - allow self-signed certificate config option in nextcloud (it may be needed sometimes)
# V 1.4.2 - 10.02.2023
# - completely disable opcache because of many segfaults even when JIT is completely disabled
# V 1.4.1 - 08.02.2023
# - opcache jit cache in php has been disabled because of many segfaults reported
# V 1.4 - 31.01.2023
# - fixes thanks to "maybe" user from hejto.pl portal (ufw, redis, chmods etc.) Thank You!
# V 1.3 - 30.01.2023
# - fix PHP 8.1 installing
# - more data stored to log for better error handling
# V 1.2 - 23.01.2023
# - some performance fixes (better support for large files)
# V 1.1 - 04.08.2022
# - added support for adding domain name as command line variable (with let's ecnrypt support)
# - added crontab job for certbot (Let's encrypt) and some more description
# V 1.0 - 20.06.2022
# - initial version based on private install script (for EL)
# 
# Future plans:
# - add High Performance Backend (HPB) for Nextcloud (Push Service) 
# - make backup of Nextcloud script (excluding users files) and database for recovery before upgrade
# - add option to restore previosly created backup.

export LC_ALL=C

ver=1.10
cpu=$( uname -m )
user=$( whoami )
debvf=/etc/debian_version
ubuvf=/etc/dpkg/origins/ubuntu
if [ -e $debvf ]
then
	if [ -e $ubuvf ]
	then
		ubuv=$( cat /etc/lsb-release | grep "Ubuntu 22" | awk -F '"' '{print $2}' )
		unset debv
		debv=$ubuv
		ubu19=$( cat /etc/lsb-release | grep "Ubuntu 19" )
		ubu20=$( cat /etc/lsb-release | grep "Ubuntu 20" )
		ubu21=$( cat /etc/lsb-release | grep "Ubuntu 21" )
		ubu22=$( cat /etc/lsb-release | grep "Ubuntu 22" )
		ubu23=$( cat /etc/lsb-release | grep "Ubuntu 23" )
	else
	debv=$( cat $debvf )
	fi
fi
elvf=/etc/redhat-release
fedvf=/etc/fedora-release
if [ -e $elvf ]
then
	elv=$( cat $elvf )
	el6=$( cat /etc/redhat-release | grep "release 6" )
	el7=$( cat /etc/redhat-release | grep "release 7" )
	el8=$( cat /etc/redhat-release | grep "release 8" )
	el9=$( cat /etc/redhat-release | grep "release 9" )
	el10=$( cat /etc/redhat-release | grep "release 10" )
	if [ -e $fedvf ]
	then
		fed36=$( cat /etc/redhat-release | grep "release 36" )
		fed37=$( cat /etc/redhat-release | grep "release 37" )
		fed38=$( cat /etc/redhat-release | grep "release 38" )
		fed39=$( cat /etc/redhat-release | grep "release 39" )
	fi
fi
addr=$( hostname -I )
addr1=$( hostname -I | awk '{print $1}' )
cdir=$( pwd )
if [ -e $debvf ]
then
	websrv_usr=www-data
fi
if [ -e $elvf ]
then
	websrv_usr=apache
fi
lang=""
mail=""
dm=""
nv=""
fdir=""
insl=/var/log/nextcloud-installer.log
ver_file=/var/local/nextcloud-installer.ver
scrpt=nextcloud-ins

while [ "$#" -gt 0 ]; do
    case "$1" in
        -lang=*) lang="${1#*=}" ;;
        -mail=*) mail="${1#*=}" ;;
		-dm=*) dm="${1#*=}" ;;
		-nv=*) nv="${1#*=}" ;;
		-fdir=*) fdir="${1#*=}" ;;
        *) echo "Unknown parameter: $1" >&2; echo "Remember to add one, or more variables after equals sign."; echo -e "Eg. \e[1;32m-\e[39;0mmail\e[1;32m=\e[39;0mmail@example.com \e[1;32m-\e[39;0mlang\e[1;32m=\e[39;0mpl \e[1;32m-\e[39;0mdm\e[1;32m=\e[39;0mdomain.com \e[1;32m-\e[39;0mnv\e[1;32m=\e[39;0m24 \e[1;32m-\e[39;0mfdir\e[1;32m=\e[39;0m/mnt/sdc5/nextcloud-data"; exit 1 ;;
    esac
    shift
done

# More complex tasks are functions now:

function restart_websrv {
	if [ -e $debvf ]
	then
		systemctl stop apache2 >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		systemctl stop httpd >> $insl 2>&1
		if [ -d /etc/opt/remi/php74 ]
		then
			systemctl stop php74-php-fpm >> $insl 2>&1
			rm -rf /var/opt/remi/php74/lib/php/opcache/* >> $insl 2>&1
			systemctl start php74-php-fpm >> $insl 2>&1
		fi
	fi
	if [ -d /etc/opt/remi/php81 ]
	then
		systemctl stop php81-php-fpm >> $insl 2>&1
		rm -rf /var/opt/remi/php81/lib/php/opcache/* >> $insl 2>&1
		systemctl start php81-php-fpm >> $insl 2>&1
	fi
	if [ -d /etc/opt/remi/php82 ]
	then
		systemctl stop php82-php-fpm >> $insl 2>&1
		rm -rf /var/opt/remi/php82/lib/php/opcache/* >> $insl 2>&1
		systemctl start php82-php-fpm >> $insl 2>&1
	fi
	if [ -d /etc/opt/remi/php83 ]
	then
		systemctl stop php83-php-fpm >> $insl 2>&1
		rm -rf /var/opt/remi/php83/lib/php/opcache/* >> $insl 2>&1
		systemctl start php83-php-fpm >> $insl 2>&1
	fi
	if [ -d /etc/opt/remi/php84 ]
	then
		systemctl stop php84-php-fpm >> $insl 2>&1
		rm -rf /var/opt/remi/php84/lib/php/opcache/* >> $insl 2>&1
		systemctl start php84-php-fpm >> $insl 2>&1
	fi
	if [ -d /etc/opt/remi/php85 ]
	then
		systemctl stop php85-php-fpm >> $insl 2>&1
		rm -rf /var/opt/remi/php85/lib/php/opcache/* >> $insl 2>&1
		systemctl start php85-php-fpm >> $insl 2>&1
	fi
	if [ -d /etc/opt/remi/php86 ]
	then
		systemctl stop php86-php-fpm >> $insl 2>&1
		rm -rf /var/opt/remi/php86/lib/php/opcache/* >> $insl 2>&1
		systemctl start php86-php-fpm >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		systemctl start httpd >> $insl 2>&1
	fi
	if [ -e $debvf ]
	then
		systemctl start apache2 >> $insl 2>&1
	fi
}

function maintenance_window_setup {
	if grep -q "maintenance_window_start" "/var/www/nextcloud/config/config.php"
	then
		echo "!!!!!!! Maintenance window time already configured." >> $insl 2>&1
	else
		echo "!!!!!!! Adding maintenance window time inside NC config." >> $insl 2>&1
		sed -i "/installed' => true,/a\ \ 'maintenance_window_start' => '1'," /var/www/nextcloud/config/config.php
	fi
}

# Check if Nextcloud was updated with nv variable, and if yes, skip doing anything to not brake it.
# This is version made for newer version of script, so it report that it was running under $ver_file.
function nv_check_upd {
	echo "Older version of Nextcloud configured, skipping updates and exit."
	echo "Older version of Nextcloud configured, skipping updates and exit." >> $insl 2>&1
	echo -e "pver=$ver lang=$lang mail=$mail dm=$dm nv=$nv fdir=$fdir\n$(</var/local/nextcloud-installer.ver)" > $ver_file
	echo -e "Version $ver was succesfully installed at $(date +%d-%m-%Y_%H:%M:%S)\n$(</var/local/nextcloud-installer.ver)" > $ver_file
	mv $cdir/$scrpt.sh $scrpt-$(date +"%FT%H%M").sh
	unset LC_ALL
	exit 0
}

function nv_check_upd_cur {
	echo "Older version of Nextcloud configured, skipping updates and exit."
	echo "Older version of Nextcloud configured, skipping updates and exit." >> $insl 2>&1
	mv $cdir/$scrpt.sh $scrpt-$(date +"%FT%H%M").sh
	unset LC_ALL
	exit 0
}

function nv_upd_simpl {
	rm -rf /var/www/nextcloud/composer.lock >> $insl 2>&1
	rm -rf /var/www/nextcloud/package-lock.json >> $insl 2>&1
	rm -rf /var/www/nextcloud/package.json >> $insl 2>&1
	rm -rf /var/www/nextcloud/composer.json >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ db:add-missing-indices >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ upgrade >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ maintenance:mode --off >> $insl 2>&1
}

function update_os {
	if [ -e $debvf ]
	then
		apt-get update -o DPkg::Lock::Timeout=-1 >> $insl 2>&1 && apt-get upgrade -y -o DPkg::Lock::Timeout=-1 >> $insl 2>&1 && apt-get autoremove -y >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		dnf update -y -q >> $insl 2>&1
	fi
}

function install_soft {
	echo "!!!!!!! Installing all needed standard packages" >> $insl 2>&1
	if [ -e $debvf ]
	then
		DEBIAN_FRONTEND=noninteractive
		apt-get install -y -o DPkg::Lock::Timeout=-1 git lbzip2 unzip zip lsb-release locales-all rsync wget curl sed screen gawk mc sudo net-tools ethtool vim nano ufw apt-transport-https ca-certificates software-properties-common miniupnpc jq libfontconfig1 libfuse2 socat tree ffmpeg imagemagick webp libreoffice ghostscript bindfs >> $insl 2>&1
		yes | sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq -o DPkg::Lock::Timeout=-1 install ddclient  >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		# Disabling SELinux for testing purposes here. By default just let it run and configure things instead.
		# setenforce 0 >> $insl 2>&1
		# grubby --update-kernel ALL --args selinux=0 >> $insl 2>&1
		# sed --in-place=.bak 's/^SELINUX\=enforcing/SELINUX\=permissive/g' /etc/selinux/config
		
		if [ -e $fedvf ]
		then
			dnf install -y -q https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm >> $insl 2>&1
			dnf config-manager -y --enable fedora-cisco-openh264 >> $insl 2>&1
		else
			dnf -q config-manager --set-enabled crb && dnf install -y -q epel-release >> $insl 2>&1
			dnf install -q --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm -y >> $insl 2>&1
			dnf install -q --nogpgcheck https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm -y >> $insl 2>&1
		fi
		dnf install -y -q git lbzip2 unzip zip lsb-release rsync wget curl sed screen gawk mc sudo net-tools ethtool vim nano ca-certificates miniupnpc jq fontconfig-devel socat tree ffmpeg ImageMagick libwebp libreoffice ghostscript ddclient >> $insl 2>&1
	fi
}

function install_php81 {
	if [ -e $debvf ]
	then
		curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg >> $insl 2>&1
		sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' >> $insl 2>&1
		apt-get update >> $insl 2>&1
		apt-get install -y -o DPkg::Lock::Timeout=-1 php8.1 libapache2-mod-php8.1 libmagickcore-6.q16-6-extra php8.1-mysql php8.1-common php8.1-redis php8.1-dom php8.1-curl php8.1-exif php8.1-fileinfo php8.1-bcmath php8.1-gmp php8.1-imagick php8.1-mbstring php8.1-xml php8.1-zip php8.1-iconv php8.1-intl php8.1-simplexml php8.1-xmlreader php8.1-ftp php8.1-ssh2 php8.1-sockets php8.1-gd php8.1-imap php8.1-soap php8.1-xmlrpc php8.1-apcu php8.1-dev php8.1-cli >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		if [ -e $fedvf ]
		then
			dnf install -y -q https://rpms.remirepo.net/fedora/remi-release-39.rpm >> $insl 2>&1
			dnf config-manager --set-enabled remi
		else
			dnf install -y -q https://rpms.remirepo.net/enterprise/remi-release-9.rpm >> $insl 2>&1
		fi
		dnf install -y -q php81 php81-php-apcu php81-php-opcache php81-php-mysql php81-php-bcmath php81-php-common php81-php-geos php81-php-gmp php81-php-pecl-imagick-im7 php81-php-pecl-lzf php81-php-pecl-mcrypt php81-php-pecl-recode php81-php-process php81-php-zstd php81-php-redis php81-php-dom php81-php-curl php81-php-exif php81-php-fileinfo php81-php-mbstring php81-php-xml php81-php-zip php81-php-iconv php81-php-intl php81-php-simplexml php81-php-xmlreader php81-php-ftp php81-php-ssh2 php81-php-sockets php81-php-gd php81-php-imap php81-php-soap php81-php-xmlrpc php81-php-apcu php81-php-cli php81-php-ast php81-php-brotli php81-php-enchant php81-php-ffi php81-php-lz4 php81-php-phalcon5 php81-php-phpiredis php81-php-smbclient php81-php-tidy php81-php-xz >> $insl 2>&1
		dnf install -y -q php81-syspaths php81-mod_php >> $insl 2>&1
		ln -s /var/opt/remi/php81/log/php-fpm /var/log/php81-fpm
	fi
}

function install_php82 {
	if [ -e $debvf ]
	then
		if [ -e $ubuvf ]
		then
			add-apt-repository -y ppa:ondrej/php  >> $insl 2>&1
			DEBIAN_FRONTEND=noninteractive
		else
			curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg >> $insl 2>&1
			sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' >> $insl 2>&1
		fi
		apt-get update >> $insl 2>&1
		apt-get install -y -o DPkg::Lock::Timeout=-1 php8.2 libapache2-mod-php8.2 libmagickcore-6.q16-6-extra php8.2-mysql php8.2-common php8.2-bz2 php8.2-redis php8.2-dom php8.2-curl php8.2-exif php8.2-fileinfo php8.2-bcmath php8.2-gmp php8.2-imagick php8.2-mbstring php8.2-xml php8.2-zip php8.2-iconv php8.2-intl php8.2-simplexml php8.2-xmlreader php8.2-ftp php8.2-ssh2 php8.2-sockets php8.2-gd php8.2-imap php8.2-soap php8.2-xmlrpc php8.2-apcu php8.2-dev php8.2-cli >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		if [ -e $fedvf ]
		then
			dnf install -y -q https://rpms.remirepo.net/fedora/remi-release-39.rpm >> $insl 2>&1
			dnf config-manager --set-enabled remi
		else
			dnf install -y -q https://rpms.remirepo.net/enterprise/remi-release-9.rpm >> $insl 2>&1
		fi
		dnf install -y -q php82 php82-php-apcu php82-php-opcache php82-php-mysql php82-php-bcmath php82-php-common php82-php-geos php82-php-gmp php82-php-pecl-imagick-im7 php82-php-pecl-lzf php82-php-pecl-mcrypt php82-php-pecl-recode php82-php-process php82-php-zstd php82-php-redis php82-php-dom php82-php-curl php82-php-exif php82-php-fileinfo php82-php-mbstring php82-php-xml php82-php-zip php82-php-iconv php82-php-intl php82-php-simplexml php82-php-xmlreader php82-php-ftp php82-php-ssh2 php82-php-sockets php82-php-gd php82-php-imap php82-php-soap php82-php-xmlrpc php82-php-apcu php82-php-cli php82-php-ast php82-php-brotli php82-php-enchant php82-php-ffi php82-php-lz4 php82-php-phalcon5 php82-php-phpiredis php82-php-smbclient php82-php-tidy php82-php-xz >> $insl 2>&1
		dnf install -y -q php82-syspaths php82-mod_php >> $insl 2>&1
		ln -s /var/opt/remi/php82/log/php-fpm /var/log/php82-fpm
	fi
}

function install_php83 {
	if [ -e $debvf ]
	then
		if [ -e $ubuvf ]
		then
			add-apt-repository -y ppa:ondrej/php  >> $insl 2>&1
			DEBIAN_FRONTEND=noninteractive
		else
			curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg >> $insl 2>&1
			sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' >> $insl 2>&1
		fi
		apt-get update >> $insl 2>&1
		apt-get install -y -o DPkg::Lock::Timeout=-1 php8.3 libapache2-mod-php8.3 libmagickcore-6.q16-6-extra php8.3-mysql php8.3-common php8.3-bz2 php8.3-redis php8.3-dom php8.3-curl php8.3-exif php8.3-fileinfo php8.3-bcmath php8.3-gmp php8.3-imagick php8.3-mbstring php8.3-xml php8.3-zip php8.3-iconv php8.3-intl php8.3-simplexml php8.3-xmlreader php8.3-ftp php8.3-ssh2 php8.3-sockets php8.3-gd php8.3-imap php8.3-soap php8.3-xmlrpc php8.3-apcu php8.3-dev php8.3-cli >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		if [ -e $fedvf ]
		then
			dnf install -y -q https://rpms.remirepo.net/fedora/remi-release-39.rpm >> $insl 2>&1
			dnf config-manager --set-enabled remi
		else
			dnf install -y -q https://rpms.remirepo.net/enterprise/remi-release-9.rpm >> $insl 2>&1
		fi
		dnf install -y -q php83 php83-php-apcu php83-php-opcache php83-php-mysql php83-php-bcmath php83-php-common php83-php-geos php83-php-gmp php83-php-pecl-imagick-im7 php83-php-pecl-lzf php83-php-pecl-mcrypt php83-php-pecl-recode php83-php-process php83-php-zstd php83-php-redis php83-php-dom php83-php-curl php83-php-exif php83-php-fileinfo php83-php-mbstring php83-php-xml php83-php-zip php83-php-iconv php83-php-intl php83-php-simplexml php83-php-xmlreader php83-php-ftp php83-php-ssh2 php83-php-sockets php83-php-gd php83-php-imap php83-php-soap php83-php-xmlrpc php83-php-apcu php83-php-cli php83-php-ast php83-php-brotli php83-php-enchant php83-php-ffi php83-php-lz4 php83-php-phalcon5 php83-php-phpiredis php83-php-smbclient php83-php-tidy php83-php-xz >> $insl 2>&1
		dnf install -y -q php83-syspaths php83-mod_php >> $insl 2>&1
		ln -s /var/opt/remi/php83/log/php-fpm /var/log/php83-fpm
	fi
}

# This is function for installing currently used latest version of PHP.
function install_php {
	install_php83
}

# Check and add http2 support to Apache.
function add_http2 {
	if [ -e $debvf ]
	then
		if grep -q "Protocols" "/etc/apache2/sites-available/nextcloud.conf"
		then
			echo "!!!!!!! HTTP2 already inside vhost config." >> $insl 2>&1
		else
			echo "!!!!!!! HTTP2 adding to vhost" >> $insl 2>&1
			sed -i "/LimitRequestBody 0/a\ \ H2WindowSize 5242880" /etc/apache2/sites-available/nextcloud.conf
			sed -i "/LimitRequestBody 0/a\ \ ProtocolsHonorOrder Off" /etc/apache2/sites-available/nextcloud.conf
			sed -i "/LimitRequestBody 0/a\ \ Protocols h2 h2c http/1.1" /etc/apache2/sites-available/nextcloud.conf
		fi
	fi
}

function preview_tweaks {
	echo "!!!!!!! Preview thumbnails tweaking in NC" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 0 --value="OC\\Preview\\PNG" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 1 --value="OC\\Preview\\JPEG" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 2 --value="OC\\Preview\\GIF" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 3 --value="OC\\Preview\\BMP" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 4 --value="OC\\Preview\\XBitmap" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 5 --value="OC\\Preview\\MP3" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 6 --value="OC\\Preview\\TXT" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 7 --value="OC\\Preview\\MarkDown" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 8 --value="OC\\Preview\\OpenDocument" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 9 --value="OC\\Preview\\Krita" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 10 --value="OC\\Preview\\Illustrator" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 11 --value="OC\\Preview\\HEIC" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 12 --value="OC\\Preview\\HEIF" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 13 --value="OC\\Preview\\Movie" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 14 --value="OC\\Preview\\MSOffice2003" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 15 --value="OC\\Preview\\MSOffice2007" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 16 --value="OC\\Preview\\MSOfficeDoc" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 17 --value="OC\\Preview\\PDF" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 18 --value="OC\\Preview\\Photoshop" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 19 --value="OC\\Preview\\Postscript" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 20 --value="OC\\Preview\\StarOffice" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 21 --value="OC\\Preview\\SVG" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 22 --value="OC\\Preview\\TIFF" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 23 --value="OC\\Preview\\WEBP" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 24 --value="OC\\Preview\\EMF" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 25 --value="OC\\Preview\\Font" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enabledPreviewProviders 26 --value="OC\\Preview\\Image" >> $insl 2>&1
	if [ -e $debvf ]
	then
		sed -i 's/\(^ *<policy.*rights="\)\([^"]*\)\(".*PS.*\/>\)/\1read|write\3/1' /etc/ImageMagick-6/policy.xml
		sed -i 's/\(^ *<policy.*rights="\)\([^"]*\)\(".*PS2.*\/>\)/\1read|write\3/1' /etc/ImageMagick-6/policy.xml
		sed -i 's/\(^ *<policy.*rights="\)\([^"]*\)\(".*PS3.*\/>\)/\1read|write\3/1' /etc/ImageMagick-6/policy.xml
		sed -i 's/\(^ *<policy.*rights="\)\([^"]*\)\(".*EPS.*\/>\)/\1read|write\3/1' /etc/ImageMagick-6/policy.xml
		sed -i 's/\(^ *<policy.*rights="\)\([^"]*\)\(".*PDF.*\/>\)/\1read|write\3/1' /etc/ImageMagick-6/policy.xml
	fi
}

function php74_tweaks {
	echo "!!!!!!! PHP 7.4 config files modify." >> $insl 2>&1
	echo "PHP config files tweaking."
	if [ -e $debvf ]
	then
		php74_in1=/etc/php/7.4/apache2
		php74_in2=/etc/php/7.4/apache2/conf.d
	fi
	if [ -e $elvf ]
	then
		php74_in1=/etc/opt/remi/php74
		php74_in2=/etc/opt/remi/php74/php.d
		ln -s /var/opt/remi/php74/log/php-fpm /var/log/php-fpm
	fi
	if [ -e $debvf ]
	then
		echo 'apc.enable_cli=1' >> /etc/php/7.4/cli/conf.d/20-apcu.ini
	fi
	if [ -e $debvf ]
	then
		echo 'apc.enable_cli=1' >> $php74_in2/40-apcu.ini
	fi
	sed -i 's/\b128M\b/1024M/g' $php74_in1/php.ini
	sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' $php74_in1/php.ini
	sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' $php74_in1/php.ini
	sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' $php74_in1/php.ini
	sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' $php74_in1/php.ini
	sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' $php74_in1/php.ini
	sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' $php74_in1/php.ini
	sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' $php74_in1/php.ini
	sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' $php74_in1/php.ini
	sed -i '/MySQLi]/amysqli.cache_size = 2000' $php74_in1/php.ini
	if [ -e $debvf ]
	then
		sed -i 's/\b128M\b/1024M/g' /etc/php/7.4/cli/php.ini
		sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' /etc/php/7.4/cli/php.ini
		sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' /etc/php/7.4/cli/php.ini
		sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' /etc/php/7.4/cli/php.ini
		sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' /etc/php/7.4/cli/php.ini
		sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' /etc/php/7.4/cli/php.ini
		sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' /etc/php/7.4/cli/php.ini
		sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' /etc/php/7.4/cli/php.ini
		sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' /etc/php/7.4/cli/php.ini
		sed -i '/MySQLi]/amysqli.cache_size = 2000' /etc/php/7.4/cli/php.ini
	fi
	echo 'opcache.enable_cli=1' >> $php74_in2/10-opcache.ini
	echo 'opcache.interned_strings_buffer=64' >> $php74_in2/10-opcache.ini
	echo 'opcache.max_accelerated_files=20000' >> $php74_in2/10-opcache.ini
	echo 'opcache.memory_consumption=256' >> $php74_in2/10-opcache.ini
	echo 'opcache.save_comments=1' >> $php74_in2/10-opcache.ini
	echo 'opcache.enable=1' >> $php74_in2/10-opcache.ini
	# echo 'opcache.revalidate_freq=1' >> $php74_in2/10-opcache.ini
	# echo 'opcache.jit=disable' >> $php74_in2/10-opcache.ini
	restart_websrv
}

function php81_tweaks {
	echo "!!!!!!! PHP 8.1 config files modify." >> $insl 2>&1
	echo "PHP config files tweaking."
	if [ -e $debvf ]
	then
		php81_in1=/etc/php/8.1/apache2
		php81_in2=/etc/php/8.1/apache2/conf.d
	fi
	if [ -e $elvf ]
	then
		php81_in1=/etc/opt/remi/php81
		php81_in2=/etc/opt/remi/php81/php.d
	fi
	if [ -e $debvf ]
	then
		echo 'apc.enable_cli=1' >> /etc/php/8.1/cli/conf.d/20-apcu.ini
	fi
	if [ -e $debvf ]
	then
		echo 'apc.enable_cli=1' >> $php81_in2/40-apcu.ini
	fi
	sed -i 's/\b128M\b/1024M/g' $php81_in1/php.ini
	sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' $php81_in1/php.ini
	sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' $php81_in1/php.ini
	sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' $php81_in1/php.ini
	sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' $php81_in1/php.ini
	sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' $php81_in1/php.ini
	sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' $php81_in1/php.ini
	sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' $php81_in1/php.ini
	sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' $php81_in1/php.ini
	sed -i '/MySQLi]/amysqli.cache_size = 2000' $php81_in1/php.ini
	if [ -e $debvf ]
	then
		sed -i 's/\b128M\b/1024M/g' /etc/php/8.1/cli/php.ini
		sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' /etc/php/8.1/cli/php.ini
		sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' /etc/php/8.1/cli/php.ini
		sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' /etc/php/8.1/cli/php.ini
		sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' /etc/php/8.1/cli/php.ini
		sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' /etc/php/8.1/cli/php.ini
		sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' /etc/php/8.1/cli/php.ini
		sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' /etc/php/8.1/cli/php.ini
		sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' /etc/php/8.1/cli/php.ini
		sed -i '/MySQLi]/amysqli.cache_size = 2000' /etc/php/8.1/cli/php.ini
	fi
	echo 'opcache.enable_cli=1' >> $php81_in2/10-opcache.ini
	echo 'opcache.interned_strings_buffer=64' >> $php81_in2/10-opcache.ini
	echo 'opcache.max_accelerated_files=20000' >> $php81_in2/10-opcache.ini
	echo 'opcache.memory_consumption=256' >> $php81_in2/10-opcache.ini
	echo 'opcache.save_comments=1' >> $php81_in2/10-opcache.ini
	echo 'opcache.enable=1' >> $php81_in2/10-opcache.ini
	# echo 'opcache.revalidate_freq=1' >> $php81_in2/10-opcache.ini
	# echo 'opcache.jit=disable' >> $php81_in2/10-opcache.ini
	restart_websrv
}

function php82_tweaks {
	echo "!!!!!!! PHP 8.2 config files modify." >> $insl 2>&1
	echo "PHP config files tweaking."
	if [ -e $debvf ]
	then
		php82_in1=/etc/php/8.2/apache2
		php82_in2=/etc/php/8.2/apache2/conf.d
	fi
	if [ -e $elvf ]
	then
		php82_in1=/etc/opt/remi/php82
		php82_in2=/etc/opt/remi/php82/php.d
	fi
	if [ -e $debvf ]
	then
		echo 'apc.enable_cli=1' >> /etc/php/8.2/cli/conf.d/20-apcu.ini
	fi
	if [ -e $elvf ]
	then
		echo 'apc.enable_cli=1' >> $php82_in2/40-apcu.ini
	fi
	sed -i 's/\b128M\b/1024M/g' $php82_in1/php.ini
	sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' $php82_in1/php.ini
	sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' $php82_in1/php.ini
	sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' $php82_in1/php.ini
	sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' $php82_in1/php.ini
	sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' $php82_in1/php.ini
	sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' $php82_in1/php.ini
	sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' $php82_in1/php.ini
	sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' $php82_in1/php.ini
	sed -i '/MySQLi]/amysqli.cache_size = 2000' $php82_in1/php.ini
	if [ -e $debvf ]
	then
		sed -i 's/\b128M\b/1024M/g' /etc/php/8.2/cli/php.ini
		sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' /etc/php/8.2/cli/php.ini
		sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' /etc/php/8.2/cli/php.ini
		sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' /etc/php/8.2/cli/php.ini
		sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' /etc/php/8.2/cli/php.ini
		sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' /etc/php/8.2/cli/php.ini
		sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' /etc/php/8.2/cli/php.ini
		sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' /etc/php/8.2/cli/php.ini
		sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' /etc/php/8.2/cli/php.ini
		sed -i '/MySQLi]/amysqli.cache_size = 2000' /etc/php/8.2/cli/php.ini
	fi
	echo 'opcache.enable_cli=1' >> $php82_in2/10-opcache.ini
	echo 'opcache.interned_strings_buffer=64' >> $php82_in2/10-opcache.ini
	echo 'opcache.max_accelerated_files=20000' >> $php82_in2/10-opcache.ini
	echo 'opcache.memory_consumption=256' >> $php82_in2/10-opcache.ini
	echo 'opcache.save_comments=1' >> $php82_in2/10-opcache.ini
	echo 'opcache.enable=1' >> $php82_in2/10-opcache.ini
	# echo 'opcache.revalidate_freq=1' >> $php82_in2/10-opcache.ini
	# echo 'opcache.jit=disable' >> $php82_in2/10-opcache.ini
	restart_websrv
}

function php83_tweaks {
	echo "!!!!!!! PHP 8.3 config files modify." >> $insl 2>&1
	echo "PHP config files tweaking."
	if [ -e $debvf ]
	then
		php83_in1=/etc/php/8.3/apache2
		php83_in2=/etc/php/8.3/apache2/conf.d
		php83_inc=/etc/php/8.3/cli/php.ini
	fi
	if [ -e $elvf ]
	then
		php83_in1=/etc/opt/remi/php83
		php83_in2=/etc/opt/remi/php83/php.d
	fi
	if [ -e $debvf ]
	then
		echo 'apc.enable_cli=1' >> /etc/php/8.3/cli/conf.d/20-apcu.ini
	fi
	if [ -e $elvf ]
	then
		echo 'apc.enable_cli=1' >> $php83_in2/40-apcu.ini
	fi
	sed -i 's/\b128M\b/1024M/g' $php83_in1/php.ini
	sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' $php83_in1/php.ini
	sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' $php83_in1/php.ini
	sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' $php83_in1/php.ini
	sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' $php83_in1/php.ini
	sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' $php83_in1/php.ini
	sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' $php83_in1/php.ini
	sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' $php83_in1/php.ini
	sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' $php83_in1/php.ini
	sed -i '/MySQLi]/amysqli.cache_size = 2000' $php83_in1/php.ini
	if [ -e $debvf ]
	then
		sed -i 's/\b128M\b/1024M/g' $php83_inc
		sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' $php83_inc
		sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' $php83_inc
		sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' $php83_inc
		sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' $php83_inc
		sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' $php83_inc
		sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' $php83_inc
		sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' $php83_inc
		sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' $php83_inc
		sed -i '/MySQLi]/amysqli.cache_size = 2000' $php83_inc
	fi
	echo 'opcache.enable_cli=1' >> $php83_in2/10-opcache.ini
	echo 'opcache.interned_strings_buffer=64' >> $php83_in2/10-opcache.ini
	echo 'opcache.max_accelerated_files=20000' >> $php83_in2/10-opcache.ini
	echo 'opcache.memory_consumption=256' >> $php83_in2/10-opcache.ini
	echo 'opcache.save_comments=1' >> $php83_in2/10-opcache.ini
	echo 'opcache.enable=1' >> $php83_in2/10-opcache.ini
	# echo 'opcache.revalidate_freq=1' >> $php83_in2/10-opcache.ini
	# echo 'opcache.jit=disable' >> $php83_in2/10-opcache.ini
	restart_websrv
}

# This are tweaks for currently latest verion used.
function php_tweaks {
	php83_tweaks
}

function save_version_info {
	echo -e "pver=$ver lang=$lang mail=$mail dm=$dm nv=$nv fdir=$fdir\n$(</var/local/nextcloud-installer.ver)" > $ver_file
	echo -e "Version $ver was succesfully installed at $(date +%d-%m-%Y_%H:%M:%S)\n$(</var/local/nextcloud-installer.ver)" > $ver_file
}

function save_upg_info {
	echo -e "pver=$ver lang=$lang mail=$mail dm=$dm nv=$nv fdir=$fdir\n$(</var/local/nextcloud-installer.ver)" > $ver_file
	echo -e "Succesfully upgraded to $ver at $(date +%d-%m-%Y_%H:%M:%S)\n$(</var/local/nextcloud-installer.ver)" > $ver_file
}

function disable_sleep {
	echo "!!!!!!! Disabling sleep states." >> $insl 2>&1
	echo "Disabling sleep states:"
	systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target >> $insl 2>&1
}

# Check if nv option was used for every version, and exit without progress.
function nv_verify {
	if [ "$nv" = "24" ]
	then
		nv_check_upd
	fi
	if [ "$nv" = "25" ]
	then
		nv_check_upd
	fi
	if [ "$nv" = "26" ]
	then
		nv_check_upd
	fi
	if [ "$nv" = "27" ]
	then
		nv_check_upd
	fi
	if [ "$nv" = "28" ]
	then
		maintenance_window_setup
		nv_check_upd
	fi
	if [ "$nv" = "29" ]
	then
		nv_check_upd
	fi
}

# Unset nver variable and read fresh value
function sncver {
	unset ncver
	ncver=$( sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
}

# Check for every version and update it one by one.
function nv_update {
	sncver
	if [ "$ncver" = "26" ]
	then
		nv_upd_simpl
	fi
	sncver
	if [ "$ncver" = "26" ]
	then
		nv_upd_simpl
	fi
	sncver
	if [ "$ncver" = "26" ]
	then
		nv_upd_simpl
	fi
	sncver
	if [ "$ncver" = "27" ]
	then
		nv_upd_simpl
	fi
	sncver
	if [ "$ncver" = "27" ]
	then
		nv_upd_simpl
	fi
	sncver
	if [ "$ncver" = "27" ]
	then
		nv_upd_simpl
	fi
	sncver
	if [ "$ncver" = "28" ]
	then
		nv_upd_simpl
	fi
	sncver
	if [ "$ncver" = "28" ]
	then
		nv_upd_simpl
	fi
	sncver
	if [ "$ncver" = "28" ]
	then
		nv_upd_simpl
	fi
	if [ "$ncver" = "29" ]
	then
		nv_upd_simpl
	fi
	if [ "$ncver" = "29" ]
	then
		nv_upd_simpl
	fi
	if [ "$ncver" = "29" ]
	then
		nv_upd_simpl
	fi
}

# Collabora Office installing
function collab_inst {
	wget https://collaboraoffice.com/downloads/gpg/collaboraonline-release-keyring.gpg --directory-prefix=/usr/share/keyrings/ >> $insl 2>&1
	echo "Types: deb
URIs: https://www.collaboraoffice.com/repos/CollaboraOnline/CODE-deb
Suites: ./
Signed-By: /usr/share/keyrings/collaboraonline-release-keyring.gpg" >> /etc/apt/sources.list.d/collaboraonline.sources
	echo "deb http://deb.debian.org/debian bookworm contrib non-free" > /etc/apt/sources.list.d/contrib.list
	apt-get update >> $insl 2>&1
	apt-get install -y -o DPkg::Lock::Timeout=-1 ttf-mscorefonts-installer coolwsd code-brand collaboraoffice-dict-en collaboraofficebasis-pl collaboraoffice-dict-pl >> $insl 2>&1
	systemctl enable coolwsd >> $insl 2>&1
	coolconfig set ssl.enable true >> $insl 2>&1
	coolconfig set ssl.termination true >> $insl 2>&1
	coolconfig set storage.wopi.host $(hostname -I) >> $insl 2>&1
	# coolconfig set net.post_allow.host "192\.168\.[0-9]{1,3}\.[0-9]{1,3}"
	# coolconfig set-admin-password
	coolconfig update-system-template >> $insl 2>&1
	systemctl restart coolwsd >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ app:install richdocuments >> $insl 2>&1
	ufw allow 9980/tcp
}

echo -e "\e[38;5;214mNextcloud Install Script\e[39;0m
Version $ver for x86_64, for popular server Linux distributions.
by marcin@marcinwilk.eu - www.marcinwilk.eu"
echo "---------------------------------------------------------------------------"

if [ $user != root ]
then
    echo -e "You must be \e[38;5;214mroot\e[39;0m. Mission aborted!"
    echo -e "You are trying to start this script as: \e[1;31m$user\e[39;0m"
    exit 0
fi

if [ -e $insl ] || [ -e $ver_file ]
then
	echo "Nextcloud installer - $ver (www.marcinwilk.eu) started." >> $insl 2>&1
	date >> $insl 2>&1
	echo "---------------------------------------------------------------------------" >> $insl 2>&1
	echo "This script will try to upgrade Nextcloud and all needed services,"
	echo "based on what was done by it's previous version."
	echo ""
	echo "Trying to find preceding installer version."
	if [ -e $ver_file ]
	then
		echo "Detected previous install:"
		pverr1=$(sed -n '1p'  $ver_file)
		echo "$pverr1"
		echo "With parameters:"
		pverr2=$(sed -n '2p'  $ver_file)
		echo "$pverr2"
		echo ""
        pver=$(echo $pverr2 | awk -F'[ =]' '/ver/ {print $2}')
        lang=$(echo $pverr2 | awk -F'[ =]' '/lang/ {print $4}')
        mail=$(echo $pverr2 | awk -F'[ =]' '/mail/ {print $6}')
        dm=$(echo $pverr2 | awk -F'[ =]' '/dm/ {print $8}')
		nv=$(echo $pverr2 | awk -F'[ =]' '/nv/ {print $10}')
		fdir=$(echo $pverr2 | awk -F'[ =]' '/fdir/ {print $12}')
		if [ "$pver" = "1.5" ]
		then
			echo "Detected previous version installer." >> $insl 2>&1
			echo "$pverr1" >> $insl 2>&1
			echo "$pverr2" >> $insl 2>&1
			echo "Version 1.5 installer has been used previously."
			echo "Doing some updates if they are available."
			nv_verify
			update_os
			nv_update
			# Installing additional packages added with v1.7
			echo "Installing additional packages added with v1.7 upgrade" >> $insl 2>&1
			install_soft
			install_php82
			a2enmod http2 >> $insl 2>&1
			add_http2
			preview_tweaks
			sudo -u $websrv_usr php /var/www/nextcloud/occ db:add-missing-indices >> $insl 2>&1
			sudo -u $websrv_usr php /var/www/nextcloud/occ db:convert-filecache-bigint --no-interaction >> $insl 2>&1
			maintenance_window_setup
			rm -rf /opt/latest.zip
			rm -rf /var/www/nextcloud/config/autoconfig.php
			save_upg_info
			disable_sleep
			restart_websrv
			echo "Upgrade process finished."
			echo "Job done!"
			mv $cdir/$scrpt.sh $scrpt-$(date +"%FT%H%M").sh
			unset LC_ALL
			exit 0
		fi
		if [ "$pver" = "1.6" ]
		then
			echo "Detected previous version installer." >> $insl 2>&1
			echo "$pverr1" >> $insl 2>&1
			echo "$pverr2" >> $insl 2>&1
			echo "Version 1.6 installer has been used previously."
			echo "Doing some updates if they are available."
			nv_verify
			update_os
			nv_update
			sudo -u $websrv_usr php /var/www/nextcloud/occ db:add-missing-indices >> $insl 2>&1
			# Installing additional packages added with v1.7
			echo "Installing additional packages added with v1.7 upgrade" >> $insl 2>&1
			install_soft
			install_php82
			a2enmod http2 >> $insl 2>&1
			preview_tweaks
			add_http2
			rm -rf /opt/latest.zip
			rm -rf /var/www/nextcloud/config/autoconfig.php
			maintenance_window_setup
			save_upg_info
			disable_sleep
			restart_websrv
			echo "Upgrade process finished."
			echo "Job done!"
			mv $cdir/$scrpt.sh $scrpt-$(date +"%FT%H%M").sh
			unset LC_ALL
			exit 0
		fi
		if [ "$pver" = "1.7" ] || [ "$pver" = "1.8" ] || [ "$pver" = "1.9" ]
		then
			echo "Detected similar version already used." >> $insl 2>&1
			echo "$pverr1" >> $insl 2>&1
			echo "$pverr2" >> $insl 2>&1
			echo "Similar version already used (it means not many works ahead)."
			nv_verify
			echo "Doing some updates if they are available."
			update_os
			install_php83
			php83_tweaks
			nv_update
			sudo -u $websrv_usr php /var/www/nextcloud/occ db:add-missing-indices >> $insl 2>&1
			maintenance_window_setup
			restart_websrv
			echo "Upgrade process finished."
			echo "Job done!"
			save_upg_info
			mv $cdir/$scrpt.sh $scrpt-$(date +"%FT%H%M").sh
			unset LC_ALL
			exit 0
		fi
		if [ "$pver" = "1.10" ]
		then
			echo "Detected similar version already used." >> $insl 2>&1
			echo "$pverr1" >> $insl 2>&1
			echo "$pverr2" >> $insl 2>&1
			echo "Similar version already used (it means not many works ahead)."
			nv_verify
			echo "Doing some updates if they are available."
			update_os
			nv_update
			sudo -u $websrv_usr php /var/www/nextcloud/occ db:add-missing-indices >> $insl 2>&1
			maintenance_window_setup
			restart_websrv
			echo "Upgrade process finished."
			echo "Job done!"
			save_upg_info
			mv $cdir/$scrpt.sh $scrpt-$(date +"%FT%H%M").sh
			unset LC_ALL
			exit 0
		fi
	else
		echo "Detected installer version 1.4 or older already used."
		echo "Detected installer version 1.4 or older already used." >> $insl 2>&1
		if [ -e $elvf ] || [ -e $ubuvf ]
		then
			echo "In case of Fedora/EL/Ubuntu this is impossible, must be some error."
			echo "Highly possible that script was canceled during work."
			echo "Clearing now..."
			rm -rf $insl
			echo "Run script again, so it will start from beggining without error."
			unset LC_ALL
			exit 0
		fi
		echo "Upgrading in progress..."
		echo "Updating OS."
		echo "!!!!!!! Updating OS." >> $insl 2>&1
		update_os
		echo "Installing additional packages."
		install_soft
		restart_websrv
		echo "Setting up firewall"
		echo "Setting up firewall" >> $insl 2>&1
		ufw default allow  >> $insl 2>&1
		ufw --force enable >> $insl 2>&1
		ufw allow OpenSSH >> $insl 2>&1
		ufw allow 'WWW Full' >> $insl 2>&1
		ufw allow 7867/tcp >> $insl 2>&1
		ufw default deny >> $insl 2>&1
		ufw show added >> $insl 2>&1
		echo "OS tweaking for Redis."
		sysctl vm.overcommit_memory=1 >> $insl 2>&1
		echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
		echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

echo madvise > /sys/kernel/mm/transparent_hugepage/enabled
exit 0" >> /etc/rc.local
		chmod +x /etc/rc.local
		systemctl daemon-reload
		systemctl start rc-local
		echo "!!!!!!! Upgrading Nextcloud." >> $insl 2>&1
		echo "Upgrading Nextcloud."
		echo "Checking currently installed version." >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:get version >> $insl 2>&1
		sncver
		if [ "$ncver" = "24" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "24" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "24" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "24" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "25" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "25" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "25" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "25" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "26" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "26" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "26" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "26" ]
		then
			nv_upd_simpl
		fi
		if [ "$ncver" = "27" ]
		then
			echo "Installing PHP 8.2"
			install_php82
			php82_tweaks
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "27" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "27" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "28" ]
		then
			echo "Installing PHP 8.2"
			install_php82
			php82_tweaks
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "28" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "28" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "29" ]
		then
			echo "Installing PHP 8.3"
			install_php83
			php83_tweaks
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "29" ]
		then
			nv_upd_simpl
		fi
		sncver
		if [ "$ncver" = "29" ]
		then
			nv_upd_simpl
		fi
		sudo -u $websrv_usr php /var/www/nextcloud/occ db:add-missing-indices >> $insl 2>&1
		echo ""
		echo ""
		echo "Nextcloud upgraded to version:" >> $insl 2>&1
		echo "Nextcloud upgraded to version:"
		sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:get version >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:get version
		echo "Adding some more Nextcloud tweaks."
		sudo -u $websrv_usr php /var/www/nextcloud/occ maintenance:repair >> $insl 2>&1
		echo ""
		sed -i "/installed' => true,/a\ \ 'htaccess.RewriteBase' => '/'," /var/www/nextcloud/config/config.php
		maintenance_window_setup
		sudo -u $websrv_usr php /var/www/nextcloud/occ maintenance:update:htaccess >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ db:add-missing-indices >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ db:convert-filecache-bigint --no-interaction >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set ALLOW_SELF_SIGNED --value="true" >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enable_previews --value="true" >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set preview_max_memory --value="512" >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set preview_max_x --value="12288" >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set preview_max_y --value="6912" >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set auth.bruteforce.protection.enabled --value="true" >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ app:install twofactor_totp >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ app:enable twofactor_totp >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ app:install twofactor_webauthn >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ app:enable twofactor_webauthn >> $insl 2>&1
		sudo -u $websrv_usr php /var/www/nextcloud/occ config:app:set files max_chunk_size --value="20971520" >> $insl 2>&1
		touch $ver_file
		echo "Removing PHP 8.1"
		apt-get remove -y -o DPkg::Lock::Timeout=-1 php8.1 php8.1-* >> $insl 2>&1
		a2enmod http2 >> $insl 2>&1
		a2enmod php8.3 >> $insl 2>&1
		add_http2
		preview_tweaks
		rm -rf /opt/latest.zip
		rm -rf /var/www/nextcloud/config/autoconfig.php
		systemctl restart mariadb >> $insl 2>&1
		systemctl restart redis-server >> $insl 2>&1
		restart_websrv
		disable_sleep
		save_upg_info
		echo "Upgrade process finished."
		echo "Job done!"
		mv $cdir/$scrpt.sh $scrpt-$(date +"%FT%H%M").sh
		unset LC_ALL
		exit 0
	fi
else
	echo ""
fi

# Here clean install starts!
if [ -e $debvf ] || [ -e $elvf ]
then
	if [ -n "$el5" ] || [ -n "$el6" ] || [ -n "$el7" ] || [ -n "$el8" ] || [ -n "$ubu19" ] || [ -n "$ubu20" ] || [ -n "$ubu21" ] || [ -n "$fed36" ] || [ -n "$fed37" ] || [ -n "$fed38" ]
	then
		echo "Too old main Linux distribution release, try newer."
		exit 0
	else
		echo "" > /dev/null
	fi
else
	echo "Your Linux distribution isn't supported by this script."
    echo "Mission aborted!"
    echo "Unsupported Linux distro!"
    exit 0
fi
echo "This script will automatically install Nextcloud service."
echo "Few addditional packages will be installed:"
echo "Apache, PHP, MariaDB, ddclient, Let's encrypt and more."
echo ""
echo -e "You may add some variables like -lang=, -mail=, -dm=, -nv= and -fdir="
echo "Where lang is for language, supported are: Arabic (ar), Chinese (zh),"
echo "French (fr), Hindi (hi), Polish (pl), Spanish (es) and Ukrainian (uk),"
echo "(empty/undefinied use browser language)."
echo "-mail is for e_mail address of admin, -dm for domain name,"
echo -e "that should be \e[1;32m*preconfigured\e[39;0m,"
echo "-nv for installing older versions (24,25,26,27 and 28, empty means latest),"
echo -e "-fdir let you configure \e[1;32m**\e[39;0mdirectory where Nextcloud users files are stored,"
echo 'this option will not change NC config, but mount "data" directory'
echo "to another location, and save that to fstab."
echo "If you want to use spaces between words in directory name,"
echo -e 'then put path inside double quotes, eg. -fdir="/mnt/sdx/users data folder"'
echo ""
echo "./$scrpt.sh -lang=pl -mail=my@email.com -dm=mydomain.com -nv=24 -fdir=/mnt/sdc5/nextcloud-data"
echo ""
echo "You may now cancel this script with CRTL+C,"
echo "or wait 50 seconds so it will install without"
echo "additional variables."
echo ""
echo -e "\e[1;32m*\e[39;0m - domain and router must already be configured to work with this server from Internet.\e[39;0m"
echo -e "\e[1;32m**\e[39;0m - target directory must already be prepared, for example if another disk is used, it must be already (auto)mounted.\e[39;0m"
sleep 51

if [ $cpu = x86_64 ]
then
    echo -e "Detected Kernel CPU arch. is \e[1;32mx86_64\e[39;0m!"
elif [ $cpu = i386 ]
then
    echo -e "Detected Kernel CPU arch. is \e[1;31mi386!\e[39;0m"
	echo "Sorry - only x86_64 is supported!"
	echo "Mission aborted!"
	exit 0
else
    echo "No supported kernel architecture. Aborting!"
    echo "I did not detected x86_64 or i386 kernel architecture."
    echo "It looks like your configuration isn't supported."
    echo "Mission aborted!"
    exit 0
fi

echo "Detected Supported Linux distribution:"
if [ -e $debvf ]
then
	if [ -e $ubuvf ]
	then
		echo -e "$ubuv"
	else
		echo -e "Debian Linux release $debv"
	fi
fi
if [ -e $elvf ]
then
	echo $elv
fi

touch /var/log/nextcloud-installer.log

echo "Nextcloud installer - $ver (www.marcinwilk.eu) started." >> $insl 2>&1
date >> $insl 2>&1
echo "---------------------------------------------------------------------------" >> $insl 2>&1

if [ -z "$lang" ]
then
	echo "No custom language variable used." >> $insl 2>&1
else
	echo -e "Using language variable: \e[1;32m$lang\e[39;0m"
	echo "Using language variable: $lang" >> $insl 2>&1
fi

if [ -z "$mail" ]
then
	echo "No e_mail variable used." >> $insl 2>&1
else
	echo -e "Using e_mail variable: \e[1;32m$mail\e[39;0m"
	echo "Using e_mail variable: $mail" >> $insl 2>&1
fi

if [ -z "$dm" ]
then
	echo "No custom domain name variable used." >> $insl 2>&1
else
	echo -e "Using domain variable: \e[1;32m$dm\e[39;0m"
	echo "Using domain variable: $dm" >> $insl 2>&1
fi

if [ -z "$nv" ]
then
	echo "No older version variable used." >> $insl 2>&1
else
	echo -e "Using version variable: \e[1;32m$nv\e[39;0m"
	echo "Using version variable: $nv" >> $insl 2>&1
fi

if [ -z "$fdir" ]
then
	echo "No user files directory variable used." >> $insl 2>&1
else
	echo -e "Using user files directory variable: \e[1;32m$fdir\e[39;0m"
	echo "Using user files directory variable: $fdir" >> $insl 2>&1
	if [ -e "$fdir" ]
	then
		echo "User files directory is prepared." >> $insl 2>&1
	else
		echo "ERROR: Defined Nextcloud data directory do not exist!"
		echo ""
		echo "Please prepare directory for Nextcloud user data files."
		echo "Installer will now exit, You may restart it, after directory is prepared."
		echo "Mission aborted!"
		rm -rf $insl
		exit 0
	fi
fi

# Generating passwords for database and SuperAdmin user.
echo "!!!!!!! Generating passwords for database and SuperAdmin user" >> $insl 2>&1
openssl rand -base64 30 > /root/dbpass
openssl rand -base64 30 > /root/superadminpass
mp=$( cat /root/dbpass )
mp2=$( cat /root/superadminpass )

echo "Updating OS."
echo "!!!!!!! Updating OS" >> $insl 2>&1
update_os

if [ "$lang" = "ar" ]
then
	echo "!!!!!!! Installing language packages - Arabic" >> $insl 2>&1
	if [ -e $debvf ]
	then
		apt-get install -y -o DPkg::Lock::Timeout=-1 task-arabic >> $insl 2>&1
		locale-gen >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		dnf install -y -q glibc-langpack-ar >> $insl 2>&1
	fi
	localectl set-locale LANG=ar_EG.UTF-8 >> $insl 2>&1
fi

if [ "$lang" = "zh" ]
then
	echo "!!!!!!! Installing language packages - Chinese" >> $insl 2>&1
	if [ -e $debvf ]
	then
		apt-get install -y -o DPkg::Lock::Timeout=-1 task-chinese-s task-chinese-t >> $insl 2>&1
		locale-gen >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		dnf install -y -q glibc-langpack-zh >> $insl 2>&1
	fi
	localectl set-locale LANG=zh_CN.UTF-8 >> $insl 2>&1
fi

if [ "$lang" = "fr" ]
then
	echo "!!!!!!! Installing language packages - French" >> $insl 2>&1
	if [ -e $debvf ]
	then
		apt-get install -y -o DPkg::Lock::Timeout=-1 task-french >> $insl 2>&1
		locale-gen >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		dnf install -y -q glibc-langpack-fr >> $insl 2>&1
	fi
	localectl set-locale LANG=fr_FR.UTF-8 >> $insl 2>&1
fi

if [ "$lang" = "hi" ]
then
	echo "!!!!!!! Installing language packages - Hindi" >> $insl 2>&1
	if [ -e $debvf ]
	then
		apt-get install -y -o DPkg::Lock::Timeout=-1 task-hindi >> $insl 2>&1
		locale-gen >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		dnf install -y -q glibc-langpack-hi >> $insl 2>&1
	fi
	localectl set-locale LANG=hi_IN >> $insl 2>&1
fi

if [ "$lang" = "pl" ]
then
	echo "!!!!!!! Installing language packages - Polish" >> $insl 2>&1
	if [ -e $debvf ]
	then
		apt-get install -y -o DPkg::Lock::Timeout=-1 task-polish >> $insl 2>&1
		locale-gen >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		dnf install -y -q glibc-langpack-pl >> $insl 2>&1
	fi
	timedatectl set-timezone Europe/Warsaw >> $insl 2>&1
	localectl set-locale LANG=pl_PL.UTF-8 >> $insl 2>&1
fi

if [ "$lang" = "es" ]
then
	echo "!!!!!!! Installing language packages - Spanish" >> $insl 2>&1
	if [ -e $debvf ]
	then
		apt-get install -y -o DPkg::Lock::Timeout=-1 task-spanish >> $insl 2>&1
		locale-gen >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		dnf install -y -q glibc-langpack-es >> $insl 2>&1
	fi
	localectl set-locale LANG=es_ES.UTF-8 >> $insl 2>&1
fi

if [ "$lang" = "uk" ]
then
	echo "!!!!!!! Installing language packages - Ukrainian" >> $insl 2>&1
	if [ -e $debvf ]
	then
		apt-get install -y -o DPkg::Lock::Timeout=-1 task-ukrainian >> $insl 2>&1
		locale-gen >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		dnf install -y -q glibc-langpack-uk >> $insl 2>&1
	fi
	localectl set-locale LANG=uk_UA.UTF-8 >> $insl 2>&1
fi

echo "Installing software packages. It may take some time - be patient."
echo "!!!!!!! Installing software." >> $insl 2>&1
install_soft
if [ -e $debvf ]
then
	deb12=$( sudo cat /etc/debian_version | awk -F '.' '{print $1}' )
	if [ "$deb12" = "12" ]
	then
		apt-get install -y -o DPkg::Lock::Timeout=-1 systemd-timesyncd >> $insl 2>&1
		systemctl enable systemd-timesyncd >> $insl 2>&1
		systemctl restart systemd-timesyncd >> $insl 2>&1
	else
		if [ -e $ubuvf ]
		then
			apt-get install -y -o DPkg::Lock::Timeout=-1 systemd-timesyncd >> $insl 2>&1
			systemctl enable systemd-timesyncd >> $insl 2>&1
			systemctl restart systemd-timesyncd >> $insl 2>&1
		else
			apt-get install -y -o DPkg::Lock::Timeout=-1 ntp >> $insl 2>&1
			systemctl enable ntp >> $insl 2>&1
			systemctl restart ntp >> $insl 2>&1
		fi
	fi
fi
if [ -e $elvf ]
then
	timedatectl set-ntp on
	dnf install -y -q chrony
	systemctl enable chronyd >> $insl 2>&1
	systemctl start chronyd >> $insl 2>&1
	systemctl restart systemd-timedated >> $insl 2>&1
	timedatectl set-ntp true
fi

disable_sleep
echo "Installing web server with PHP."
echo "!!!!!!! Installing web server with PHP" >> $insl 2>&1
update_os
if [ -e $debvf ]
then
	apt-get install -y -o DPkg::Lock::Timeout=-1 apache2 apache2-utils >> $insl 2>&1
	echo "ServerName 127.0.0.1" >> /etc/apache2/apache2.conf
fi
if [ -e $elvf ]
then
	dnf install -y -q httpd httpd-tools mod_ssl >> $insl 2>&1
	echo "!!!!!!! Apply HTTPD/Apache SELinux policies." >> $insl 2>&1
	setsebool httpd_unified on >> $insl 2>&1
	setsebool -P httpd_can_network_connect_db on >> $insl 2>&1
	setsebool -P httpd_can_connect_ldap on >> $insl 2>&1
	setsebool -P httpd_can_network_connect on >> $insl 2>&1
	setsebool -P httpd_can_network_memcache on >> $insl 2>&1
	setsebool -P httpd_can_sendmail on >> $insl 2>&1
	setsebool -P httpd_use_cifs on >> $insl 2>&1
	setsebool -P httpd_use_fusefs on >> $insl 2>&1
	setsebool -P httpd_use_gpg on >> $insl 2>&1
fi

if [ "$nv" = "24" ]; then
	echo "Installing PHP version 7.x for Nextcloud v24."
	echo "!!!!!!! Installing PHP version 7.x for Nextcloud v24" >> $insl 2>&1
	if [ -e $debvf ]
	then
		if [ -e $ubuvf ]
		then
			add-apt-repository -y ppa:ondrej/php >> $insl 2>&1
		else
			curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg >> $insl 2>&1
			sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' >> $insl 2>&1
		fi
		apt-get update >> $insl 2>&1
		apt-get install -y -o DPkg::Lock::Timeout=-1 php7.4 libapache2-mod-php7.4 libmagickcore-6.q16-6-extra php7.4-mysql php7.4-common php7.4-redis php7.4-dom php7.4-curl php7.4-exif php7.4-fileinfo php7.4-bcmath php7.4-gmp php7.4-imagick php7.4-mbstring php7.4-xml php7.4-zip php7.4-iconv php7.4-intl php7.4-simplexml php7.4-xmlreader php7.4-ftp php7.4-ssh2 php7.4-sockets php7.4-gd php7.4-imap php7.4-soap php7.4-xmlrpc php7.4-apcu php7.4-dev php7.4-cli >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		if [ -e $fedvf ]
		then
			dnf install -y -q https://rpms.remirepo.net/fedora/remi-release-39.rpm >> $insl 2>&1
			dnf config-manager --set-enabled remi
		else
			dnf install -y -q https://rpms.remirepo.net/enterprise/remi-release-9.rpm >> $insl 2>&1
		fi
		dnf install -y -q php74 php74-php-apcu php74-php-opcache php74-php-mysql php74-php-bcmath php74-php-common php74-php-geos php74-php-gmp php74-php-pecl-imagick-im7 php74-php-pecl-lzf php74-php-pecl-mcrypt php74-php-pecl-recode php74-php-process php74-php-zstd php74-php-redis php74-php-dom php74-php-curl php74-php-exif php74-php-fileinfo php74-php-mbstring php74-php-xml php74-php-zip php74-php-iconv php74-php-intl php74-php-simplexml php74-php-xmlreader php74-php-ftp php74-php-ssh2 php74-php-sockets php74-php-gd php74-php-imap php74-php-soap php74-php-xmlrpc php74-php-apcu php74-php-cli php74-php-ast php74-php-brotli php74-php-enchant php74-php-ffi php74-php-lz4 php74-php-phalcon5 php74-php-phpiredis php74-php-smbclient php74-php-tidy php74-php-xz >> $insl 2>&1
		dnf install -y -q php74-syspaths php74-mod_php >> $insl 2>&1
	fi
elif [ "$nv" = "25" ]; then
	echo "Installing PHP version 8.1 for Nextcloud v25."
	echo "!!!!!!! Installing PHP version 8.1 for Nextcloud v25" >> $insl 2>&1
	install_php81
elif [ "$nv" = "26" ]; then
	echo "Installing PHP version 8.1 for Nextcloud v26."
	echo "!!!!!!! Installing PHP version 8.1 for Nextcloud v26" >> $insl 2>&1
	install_php81
elif [ "$nv" = "27" ]; then
	echo "Installing PHP version 8.2 for Nextcloud v27."
	echo "!!!!!!! Installing PHP version 8.2 for Nextcloud v27" >> $insl 2>&1
	install_php82
elif [ "$nv" = "28" ]; then
	echo "Installing PHP version 8.2 for Nextcloud v28."
	echo "!!!!!!! Installing PHP version 8.2 for Nextcloud v28" >> $insl 2>&1
	install_php82
elif [ "$nv" = "29" ]; then
	echo "Installing PHP version 8.3 for Nextcloud v29."
	echo "!!!!!!! Installing PHP version 8.3 for Nextcloud v29" >> $insl 2>&1
	install_php83
elif [ -z "$nv" ]; then
	echo "Installing newest PHP version for Nextcloud."
	echo "!!!!!!! Installing newest PHP version for Nextcloud" >> $insl 2>&1
	install_php
fi

if [ -e $debvf ]
then
	a2dissite 000-default >> $insl 2>&1
	systemctl enable apache2 >> $insl 2>&1
	restart_websrv
fi
if [ -e $elvf ]
then
	systemctl enable httpd >> $insl 2>&1
	restart_websrv
fi

echo "Setting up firewall"
echo "!!!!!!! Setting up firewall" >> $insl 2>&1
if [ -e $debvf ]
then
	ufw default allow  >> $insl 2>&1
	ufw --force enable >> $insl 2>&1
	ufw allow OpenSSH >> $insl 2>&1
	ufw allow 'WWW Full' >> $insl 2>&1
	ufw allow 'Apache Full' >> $insl 2>&1
	ufw allow 7867/tcp >> $insl 2>&1
	ufw default deny >> $insl 2>&1
	ufw show added >> $insl 2>&1
fi
if [ -e $elvf ]
then
	firewall-cmd --permanent --add-service=http >> $insl 2>&1
	firewall-cmd --permanent --add-service=https >> $insl 2>&1
	firewall-cmd --permanent --add-service=ssh >> $insl 2>&1
	firewall-cmd --permanent --add-port=7867/tcp >> $insl 2>&1
	firewall-cmd --reload >> $insl 2>&1
fi

echo "Simple PHP testing..."
echo "!!!!!!! PHP check:" >> $insl 2>&1
touch test.php
echo '<?php
   echo "PHP is working! \n";
?>' >> test.php
php test.php
php test.php >> $insl 2>&1
echo '<?php
   phpinfo();
?>' >> info.php
php info.php >> $insl 2>&1
rm -rf test.php >> $insl 2>&1
rm -rf info.php >> $insl 2>&1

# Tweaks for redis first.
if [ -e $debvf ]
then
	sysctl vm.overcommit_memory=1 >> $insl 2>&1
	echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
	touch /etc/rc.local
	echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

echo madvise > /sys/kernel/mm/transparent_hugepage/enabled
exit 0
" >> /etc/rc.local
	chmod +x /etc/rc.local
	systemctl daemon-reload
	systemctl start rc-local
	# REDIS cache configure, adding socket for faster communication on local host.
	apt-get install -y -o DPkg::Lock::Timeout=-1 redis-server >> $insl 2>&1
	sed -i '/# unixsocketperm 700/aunixsocketperm 777' /etc/redis/redis.conf
	sed -i '/# unixsocketperm 700/aunixsocket /var/run/redis/redis.sock' /etc/redis/redis.conf
	usermod -a -G redis $websrv_usr
	systemctl restart redis >> $insl 2>&1
fi
if [ -e $elvf ]
then
	sysctl vm.overcommit_memory=1 >> $insl 2>&1
	echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
	echo madvise > /sys/kernel/mm/transparent_hugepage/enabled
	setsebool -P daemons_enable_cluster_mode 1
	dnf install -y -q redis >> $insl 2>&1
	mkdir /var/run/redis
	chown redis:redis /var/run/redis
	chmod 777 /var/run/redis
	sed -i '/# unixsocketperm 700/aunixsocketperm 777' /etc/redis/redis.conf
	sed -i '/# unixsocketperm 700/aunixsocket /var/run/redis/redis.sock' /etc/redis/redis.conf
	sed -i '/# supervised auto/asupervised systemd' /etc/redis/redis.conf
	# Setting up Redis SELinux permissions.
	setsebool -P redis_enable_notify 1 >> $insl 2>&1
	setsebool -P daemons_dontaudit_scheduling 1 >> $insl 2>&1
	setsebool -P fips_mode 1 >> $insl 2>&1
	setsebool -P nscd_use_shm 1 >> $insl 2>&1
	
	systemctl start redis.service >> $insl 2>&1
	echo "!!!!!!! Retrying start Redis service, for unknown reason secondary start is working under Rocky Linux 9." >> $insl 2>&1 
	systemctl start redis.service >> $insl 2>&1
	systemctl start redis.service >> $insl 2>&1
	systemctl enable redis >> $insl 2>&1
fi

echo "!!!!!!! Configuring PHP options" >> $insl 2>&1
if [ "$nv" = "24" ]; then
	php74_tweaks
elif [ "$nv" = "25" ]; then
	php81_tweaks
elif [ "$nv" = "26" ]; then
	php81_tweaks
elif [ "$nv" = "27" ]; then
	php82_tweaks
elif [ "$nv" = "28" ]; then
	php82_tweaks
elif [ "$nv" = "29" ]; then
	php83_tweaks
elif [ -z "$nv" ]; then
	php_tweaks
fi
echo "!!!!!!! Creating certificates for localhost and vhost" >> $insl 2>&1
echo "Generating keys & certificates for web access."
# Creating certificate for localhost
touch /opt/open_ssl.conf
echo '[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = NX
ST = Internet
L = Unknown
O = Nextcloud
OU = NAS
CN = Nextcloud Service
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
DNS.2 = local' >> /opt/open_ssl.conf
# echo '' >> open_ssl.conf
openssl req -x509 -nodes -days 4096 -newkey rsa:2048 -keyout /opt/nextcloud.key -out /opt/nextcloud.crt -config /opt/open_ssl.conf -extensions 'v3_req' >> $insl 2>&1
mv /opt/nextcloud.crt /etc/ssl/certs/nextcloud.crt >> $insl 2>&1
if [ -e $elvf ]
then
	mkdir /etc/ssl/private
fi
mv /opt/nextcloud.key /etc/ssl/private/nextcloud.key >> $insl 2>&1
# Creating VHost for Apache.
if [ -e $debvf ]
then
	echo '<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  # ServerName localhost
  DocumentRoot /var/www/nextcloud
  Protocols h2 h2c http/1.1
  ProtocolsHonorOrder Off
  H2WindowSize 5242880
  
  <Directory /var/www/nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
  
  LimitRequestBody 0
  
  # ProxyPass /push/ws ws://127.0.0.1:7867/ws
  # ProxyPass /push/ http://127.0.0.1:7867/
  # ProxyPassReverse /push/ http://127.0.0.1:7867/
  
  ErrorLog ${APACHE_LOG_DIR}/error.log
  CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
<VirtualHost *:443>
  ServerAdmin webmaster@localhost
  # ServerName localhost
  DocumentRoot /var/www/nextcloud
  Protocols h2 h2c http/1.1
  ProtocolsHonorOrder Off
  H2WindowSize 5242880
  
  <Directory /var/www/nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
  
  LimitRequestBody 0
  
  # ProxyPass /push/ws ws://127.0.0.1:7867/ws
  # ProxyPass /push/ http://127.0.0.1:7867/
  # ProxyPassReverse /push/ http://127.0.0.1:7867/
  
  ErrorLog ${APACHE_LOG_DIR}/error.log
  CustomLog ${APACHE_LOG_DIR}/access.log combined
  SSLEngine on
  SSLCertificateFile      /etc/ssl/certs/nextcloud.crt
  SSLCertificateKeyFile /etc/ssl/private/nextcloud.key
</VirtualHost>
' > /etc/apache2/sites-available/nextcloud.conf

a2enmod ssl >> $insl 2>&1
a2enmod rewrite >> $insl 2>&1
a2enmod headers >> $insl 2>&1
a2enmod env >> $insl 2>&1
a2enmod dir >> $insl 2>&1
a2enmod mime >> $insl 2>&1
a2enmod proxy >> $insl 2>&1
a2enmod http2 >> $insl 2>&1
# a2enmod proxy_http >> $insl 2>&1
# a2enmod proxy_wstunnel >> $insl 2>&1
a2ensite nextcloud.conf >> $insl 2>&1
fi

if [ -e $elvf ]
then
	echo '<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  # ServerName localhost
  DocumentRoot /var/www/nextcloud
  Protocols h2 h2c http/1.1
  ProtocolsHonorOrder Off
  H2WindowSize 5242880
  
  <Directory /var/www/nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
  
  LimitRequestBody 0
  
  # ProxyPass /push/ws ws://127.0.0.1:7867/ws
  # ProxyPass /push/ http://127.0.0.1:7867/
  # ProxyPassReverse /push/ http://127.0.0.1:7867/
</VirtualHost>
<VirtualHost *:443>
  ServerAdmin webmaster@localhost
  # ServerName localhost
  DocumentRoot /var/www/nextcloud
  Protocols h2 h2c http/1.1
  ProtocolsHonorOrder Off
  H2WindowSize 5242880
  
  <Directory /var/www/nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
  
  LimitRequestBody 0
  
  # ProxyPass /push/ws ws://127.0.0.1:7867/ws
  # ProxyPass /push/ http://127.0.0.1:7867/
  # ProxyPassReverse /push/ http://127.0.0.1:7867/
  
  SSLEngine on
  SSLCertificateFile      /etc/ssl/certs/nextcloud.crt
  SSLCertificateKeyFile /etc/ssl/private/nextcloud.key
</VirtualHost>
' > /etc/httpd/conf.d/nextcloud.conf
sed -i.bak 's/^DocumentRoot "\/var\/www\/html"/DocumentRoot "\/var\/www\/nextcloud"/g' /etc/httpd/conf/httpd.conf
fi

echo "Installing MariaDB database server."
echo "!!!!!!! Installing MariaDB database server" >> $insl 2>&1
if [ -e $debvf ]
then
	apt-get install -y -o DPkg::Lock::Timeout=-1 mariadb-server >> $insl 2>&1
fi

if [ -e $elvf ]
then
	dnf install -y -q mariadb-server mariadb >> $insl 2>&1
fi
# Adding MariaDB options.
if [ -e $debvf ]
then
	touch /etc/mysql/mariadb.conf.d/70-nextcloud.cnf
	echo '[server]
skip-name-resolve
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 32M
innodb_max_dirty_pages_pct = 90
query_cache_type = 1
query_cache_limit = 2M
query_cache_min_res_unit = 2k
query_cache_size = 64M
tmp_table_size= 64M
max_heap_table_size= 64M
slow-query-log = 1
slow-query-log-file = /var/log/mysql/slow.log
long_query_time = 1

[mysqld]
innodb_buffer_pool_size=1G
innodb_io_capacity=4000
' >> /etc/mysql/mariadb.conf.d/70-nextcloud.cnf
fi

if [ -e $elvf ]
then
	touch /etc/my.cnf.d/nextcloud.cnf
	echo '[server]
skip-name-resolve
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 32M
innodb_max_dirty_pages_pct = 90
query_cache_type = 1
query_cache_limit = 2M
query_cache_min_res_unit = 2k
query_cache_size = 64M
tmp_table_size= 64M
max_heap_table_size= 64M
slow-query-log = 1
slow-query-log-file = /var/log/mariadb/slow.log
long_query_time = 1

[mysqld]
innodb_buffer_pool_size=1G
innodb_io_capacity=4000
' >> /etc/my.cnf.d/nextcloud.cnf
fi
systemctl enable mariadb >> $insl 2>&1
systemctl restart mariadb >> $insl 2>&1

# MariaDB Installed Snapshot.
echo "!!!!!!! Adding database default entries." >> $insl 2>&1
# Make sure that NOBODY can access the server without a password.
mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$mp');" >> $insl 2>&1
# Kill the anonymous users.
# mysql -e "DROP USER ''@'localhost'" >> $insl 2>&1
# Because our hostname varies we'll use some Bash magic here.
# mysql -e "DROP USER ''@'$(hostname)'" >> $insl 2>&1
# Disable remote root user access.
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')" >> $insl 2>&1
# Kill off the demo database.

# Creating database for Nextcloud.
mysql -e "SET GLOBAL innodb_default_row_format='dynamic'" >> $insl 2>&1
mysql -e "CREATE DATABASE nextdrive CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci" >> $insl 2>&1
mysql -e "GRANT ALL on nextdrive.* to 'nextcloud'@'%' identified by '$mp'" >> $insl 2>&1

# Make our changes take effect.
mysql -e "FLUSH PRIVILEGES" >> $insl 2>&1

# Importing data into database: enabling smb share in nextcloud, enabling plugins if needed.
# Export cmd: mysqldump -u root -p --all-databases --skip-lock-tables > alldb.sql
# Downloading and installing Let's encrypt mechanism.
echo "!!!!!!! Installing certbot." >> $insl 2>&1
if [ -e $debvf ]
then
	apt-get install -y -o DPkg::Lock::Timeout=-1 python3-certbot-apache >> $insl 2>&1
fi
if [ -e $elvf ]
then
	dnf install -y -q python3-certbot-apache >> $insl 2>&1
fi

# Downloading and installing Nextcloud.
echo "!!!!!!! Downloading and installing Nextcloud" >> $insl 2>&1
mkdir /var/www/nextcloud
mkdir /var/www/nextcloud/data

# Configuring/mounting data directory to specified location
echo "!!!!!!! Configuring/mounting data directory to specified location" >> $insl 2>&1
if [ -z "$fdir" ]
then
	echo "User files directory not configured." >> $insl 2>&1
else
	cp /etc/fstab /etc/fstab-nc.bak >> $insl 2>&1
	fs_fdir="${fdir// /\\040}"
	echo "$fs_fdir /var/www/nextcloud/data               none     bind        0 0" >> /etc/fstab
	mount --bind "$fdir" /var/www/nextcloud/data >> $insl 2>&1
fi

if [ -e latest.zip ]
then
	mv latest.zip $(date +"%FT%H%M")-latest.zip >> $insl 2>&1
fi

if [ "$nv" = "24" ]; then
	echo "Downloading and unpacking Nextcloud v$nv." >> $insl 2>&1
	wget -q https://download.nextcloud.com/server/releases/nextcloud-24.0.12.zip >> $insl 2>&1
	mv nextcloud-24.0.12.zip latest.zip >> $insl 2>&1
elif [ "$nv" = "25" ]; then
	echo "Downloading and unpacking Nextcloud v$nv." >> $insl 2>&1
	wget -q https://download.nextcloud.com/server/releases/nextcloud-25.0.9.zip >> $insl 2>&1
	mv nextcloud-25.0.9.zip latest.zip >> $insl 2>&1
elif [ "$nv" = "26" ]; then
	echo "Downloading and unpacking Nextcloud v$nv." >> $insl 2>&1
	wget -q https://download.nextcloud.com/server/releases/nextcloud-26.0.4.zip >> $insl 2>&1
	mv nextcloud-26.0.4.zip latest.zip >> $insl 2>&1
elif [ "$nv" = "27" ]; then
	echo "Downloading and unpacking Nextcloud v$nv." >> $insl 2>&1
	wget -q https://download.nextcloud.com/server/releases/nextcloud-27.1.7.zip >> $insl 2>&1
	mv nextcloud-27.1.7.zip latest.zip >> $insl 2>&1
elif [ "$nv" = "28" ]; then
	echo "Downloading and unpacking Nextcloud v$nv." >> $insl 2>&1
	wget -q https://download.nextcloud.com/server/releases/nextcloud-28.0.3.zip >> $insl 2>&1
	mv nextcloud-28.0.3.zip latest.zip >> $insl 2>&1
elif [ "$nv" = "29" ]; then
	echo "Downloading and unpacking Nextcloud v$nv." >> $insl 2>&1
	wget -q https://download.nextcloud.com/server/releases/latest.zip >> $insl 2>&1
	mv nextcloud-29.0.0beta4.zip latest.zip >> $insl 2>&1
fi

if [ -e latest.zip ]
then
	unzip -q latest.zip -d /var/www >> $insl 2>&1
else
	wget -q https://download.nextcloud.com/server/releases/latest.zip >> $insl 2>&1
	unzip -q latest.zip -d /var/www >> $insl 2>&1
fi
chown -R $websrv_usr:$websrv_usr /var/www/

# Preparing SELinux permissions
if [ -e $elvf ]
then
	echo "!!!!!!! Apply Nextcloud SELinux permissions." >> $insl 2>&1
	semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/data(/.*)?' >> $insl 2>&1
	semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/config(/.*)?' >> $insl 2>&1
	semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/apps(/.*)?' >> $insl 2>&1
	semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/.htaccess' >> $insl 2>&1
	semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/.user.ini' >> $insl 2>&1
	semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/3rdparty/aws/aws-sdk-php/src/data/logs(/.*)?' >> $insl 2>&1
	restorecon -Rv '/var/www/nextcloud/' >> $insl 2>&1
fi

# Making Nextcloud preconfiguration.
echo "!!!!!!!!!!! Making Nextcloud preconfiguration." >> $insl 2>&1
touch /var/www/nextcloud/config/autoconfig.php
echo '<?php' >> /var/www/nextcloud/config/autoconfig.php
echo '$AUTOCONFIG = array(' >> /var/www/nextcloud/config/autoconfig.php
echo '  "directory"     => "/var/www/nextcloud/data",' >> /var/www/nextcloud/config/autoconfig.php
echo '  "mysql.utf8mb4"     => true,' >> /var/www/nextcloud/config/autoconfig.php
echo '  "dbtype"        => "mysql",' >> /var/www/nextcloud/config/autoconfig.php
echo '  "dbname"        => "nextdrive",' >> /var/www/nextcloud/config/autoconfig.php
echo '  "dbuser"        => "nextcloud",' >> /var/www/nextcloud/config/autoconfig.php
echo "  \"dbpass\"        => \"$mp\"," >> /var/www/nextcloud/config/autoconfig.php
echo '  "dbhost"        => "localhost",' >> /var/www/nextcloud/config/autoconfig.php
echo '  "dbtableprefix" => "1c_",' >> /var/www/nextcloud/config/autoconfig.php
echo '  "adminlogin"    => "SuperAdmin",' >> /var/www/nextcloud/config/autoconfig.php
echo "  \"adminpass\"     => \"$mp2\"," >> /var/www/nextcloud/config/autoconfig.php
echo ');' >> /var/www/nextcloud/config/autoconfig.php

sudo -u $websrv_usr php /var/www/nextcloud/occ maintenance:install --database \
"mysql" --database-name "nextdrive"  --database-user "nextcloud" --database-pass \
"$mp" --admin-user "SuperAdmin" --admin-pass "$mp2" >> $insl 2>&1

if [ "$lang" = "ar" ]
then
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set default_language --value="ar" >> $insl 2>&1
fi

if [ "$lang" = "zh" ]
then
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set default_language --value="zh" >> $insl 2>&1
fi

if [ "$lang" = "fr" ]
then
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set default_language --value="fr" >> $insl 2>&1
fi

if [ "$lang" = "hi" ]
then
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set default_language --value="hi" >> $insl 2>&1
fi

if [ "$lang" = "pl" ]
then
	# Adding default language and locales
	#  'default_language' => 'pl',
	#  'default_locale' => 'pl',
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set default_language --value="pl" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set default_locale --value="pl_PL" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set default_phone_region --value="PL" >> $insl 2>&1
fi

if [ "$lang" = "es" ]
then
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set default_language --value="es" >> $insl 2>&1
fi

if [ "$lang" = "uk" ]
then
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set default_language --value="uk" >> $insl 2>&1
fi

# Enabling Redis in config file - default cache engine now.
sed -i "/installed' => true,/a\ \ 'memcache.local' => '\\\OC\\\Memcache\\\Redis',\n\ \ 'filelocking.enabled' => true,\n \ 'memcache.locking' => '\\\OC\\\Memcache\\\Redis',\n \ 'memcache.distributed' => '\\\OC\\\Memcache\\\Redis',\n \ 'redis' =>\n \ array (\n \  \ 'host' => '/var/run/redis/redis.sock',\n \  \ 'port' => 0,\n \  \ 'dbindex' => 0,\n \  \ 'timeout' => 600.0,\n \ )," /var/www/nextcloud/config/config.php

# APCu cacheing
# sed -i "/installed' => true,/a\ \ 'memcache.local' => '\\\OC\\\Memcache\\\APCu'," /var/www/nextcloud/config/config.php

echo "Tweaking Nextcloud configuration, adding IP's, installing NC apps etc."

# Disabling info about creating free account on shared pages/links when logged out (because it is missleading for private nextcloud instances).
sed -i "/installed' => true,/a\ \ 'simpleSignUpLink.shown' => false," /var/www/nextcloud/config/config.php

# Setting up maintenance window start time to 1 am (UTC).
maintenance_window_setup

# Command below should do nothing, but once in the past i needed that, so let it stay here...
sudo -u $websrv_usr php /var/www/nextcloud/occ db:add-missing-indices >> $insl 2>&1

# Enabling plugins. Adding more trusted domains.
# Preparing list of local IP addresses to add.
hostname -I | xargs -n1 >> /root/ips.local
</root/ips.local awk '{print "sudo -u '"$websrv_usr"' php /var/www/nextcloud/occ config:system:set trusted_domains " NR " --value=\x22" $1 "\x22"}' | xargs -L 1 -0  | bash >> $insl 2>&1;
sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set trusted_domains 97 --value="127.0.0.1" >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set trusted_domains 98 --value="nextdrive" >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set trusted_domains 99 --value="nextcloud" >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set ALLOW_SELF_SIGNED --value="true" >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set enable_previews --value="true" >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set preview_max_memory --value="512" >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set preview_max_x --value="12288" >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set preview_max_y --value="6912" >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set auth.bruteforce.protection.enabled --value="true" >> $insl 2>&1
mkdir /var/www/nextcloud/core/.null >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set skeletondirectory --value="core/.null" >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:install contacts >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:install notes >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:install deck >> $insl 2>&1
# sudo -u $websrv_usr php /var/www/nextcloud/occ app:install spreed >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:install calendar >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:enable calendar >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:install files_rightclick >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:enable files_rightclick >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:disable updatenotification >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:enable tasks >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:enable groupfolders >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:install twofactor_totp >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:enable twofactor_totp >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:install twofactor_webauthn >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:enable twofactor_webauthn >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:install camerarawpreviews >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ app:enable camerarawpreviews >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ config:app:set files max_chunk_size --value="20971520" >> $insl 2>&1

# Import certificate by Nextcloud so it will not cry that it'cant check for mjs support by JavaScript MIME type on server.
# Actually it do not resolve problem with information, so i think it is just another inside error ignored by NC.
sudo -u $websrv_usr php /var/www/nextcloud/occ security:certificates:import /etc/ssl/certs/nextcloud.crt >> $insl 2>&1

# Below lines will give more data if something goes wrong!
curl -I http://127.0.0.1/  >> $insl 2>&1
echo "!!!!!!!!!!! Copying nextcloud.log file after empty call for future diagnose." >> $insl 2>&1
cat /var/www/nextcloud/data/nextcloud.log >> $insl 2>&1

# Disable .htaccess blocking because we use nginx that do not use it, also it should be handled by Nextcloud itself!
# sed -i "/CONFIG = array (/a\ \ 'blacklisted_files' => array()," /var/www/nextcloud/config/config.php

if [ -e $debvf ]
then
	systemctl stop apache2 >> $insl 2>&1
fi

if [ -e $elvf ]
then
	systemctl stop httpd >> $insl 2>&1
fi

# Another lines that helped me in the past are here to stay...
# sudo -u $websrv_usr php /var/www/nextcloud/occ maintenance:mode --on >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ db:convert-filecache-bigint --no-interaction >> $insl 2>&1
# sudo -u $websrv_usr php /var/www/nextcloud/occ maintenance:mode --off >> $insl 2>&1

# Preparing cron service to run cron.php every 5 minute.
echo "!!!!!!!!!!! Creating cron configuration." >> $insl 2>&1
touch /etc/systemd/system/nextcloudcron.service
touch /etc/systemd/system/nextcloudcron.timer

echo '[Unit]' >> /etc/systemd/system/nextcloudcron.service
echo 'Description=Nextcloud cron.php job' >> /etc/systemd/system/nextcloudcron.service
echo '' >> /etc/systemd/system/nextcloudcron.service
echo '[Service]' >> /etc/systemd/system/nextcloudcron.service
echo -e "User=$websrv_usr" >> /etc/systemd/system/nextcloudcron.service
echo 'ExecStart=php -f /var/www/nextcloud/cron.php' >> /etc/systemd/system/nextcloudcron.service
echo '' >> /etc/systemd/system/nextcloudcron.service
echo '[Install]' >> /etc/systemd/system/nextcloudcron.service
echo 'WantedBy=basic.target' >> /etc/systemd/system/nextcloudcron.service

echo '[Unit]' >> /etc/systemd/system/nextcloudcron.timer
echo 'Description=Run Nextcloud cron.php every 5 minutes' >> /etc/systemd/system/nextcloudcron.timer
echo '' >> /etc/systemd/system/nextcloudcron.timer
echo '[Timer]' >> /etc/systemd/system/nextcloudcron.timer
echo 'OnBootSec=5min' >> /etc/systemd/system/nextcloudcron.timer
echo 'OnUnitActiveSec=5min' >> /etc/systemd/system/nextcloudcron.timer
echo 'Unit=nextcloudcron.service' >> /etc/systemd/system/nextcloudcron.timer
echo '' >> /etc/systemd/system/nextcloudcron.timer
echo '[Install]' >> /etc/systemd/system/nextcloudcron.timer
echo 'WantedBy=timers.target' >> /etc/systemd/system/nextcloudcron.timer

systemctl start nextcloudcron.timer >> $insl 2>&1
systemctl enable nextcloudcron.timer >> $insl 2>&1
restart_websrv
# Additional things that may fix some unknown Nextcloud problems (that appeared for me when started using v19).
chown -R $websrv_usr:$websrv_usr /var/www/nextcloud
chmod 775 /var/www/nextcloud

sudo -u $websrv_usr php /var/www/nextcloud/occ maintenance:repair >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ files:scan-app-data >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ files:scan --all >> $insl 2>&1
sudo -u $websrv_usr php /var/www/nextcloud/occ files:cleanup; >> $insl 2>&1
# sudo -u $websrv_usr php /var/www/nextcloud/occ preview:generate-all -vvv

# hide index.php from urls.
sed -i "/installed' => true,/a\ \ 'htaccess.RewriteBase' => '/'," /var/www/nextcloud/config/config.php
sudo -u $websrv_usr php /var/www/nextcloud/occ maintenance:update:htaccess >> $insl 2>&1

preview_tweaks

echo "Using UPNP to open ports for now." >> $insl 2>&1
upnpc -e "Web Server HTTP" -a $addr1 80 80 TCP >> $insl 2>&1
upnpc -e "Web Server HTTPS" -a $addr1 443 443 TCP >> $insl 2>&1

if [ -z "$dm" ]
then
	echo "Skipping additional domain configuration."
else
	echo "Configuring additional domain name."
	echo "!!!!!!! Configuring additional domain name" >> $insl 2>&1
	sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set trusted_domains 96 --value="$dm" >> $insl 2>&1
	if [ -e $debvf ]
	then
		sed -i '/ServerName localhost/aServerName '"$dm"'' /etc/apache2/sites-available/nextcloud.conf >> $insl 2>&1
	fi
	if [ -e $elvf ]
	then
		sed -i '/ServerName localhost/aServerName '"$dm"'' /etc/httpd/conf.d/nextcloud.conf >> $insl 2>&1
	fi
	echo "Configuring Let's encrypt."
	if [ -z "$mail" ]
	then
		echo "Skipping adding email configuration for Let's encrypt."
		if [ -e $debvf ]
		then
			certbot --register-unsafely-without-email --apache --agree-tos -d $dm >> $insl 2>&1
			(crontab -l 2>/dev/null; echo "0 4 1,15 * * /usr/bin/certbot renew") | crontab -
		fi
		if [ -e $elvf ]
		then
			certbot-3 --non-interactive --register-unsafely-without-email --apache --agree-tos -d $dm >> $insl 2>&1
			(crontab -l 2>/dev/null; echo "0 4 1,15 * * /usr/bin/certbot-3 renew") | crontab -
		fi
	else
		if [ -e $debvf ]
		then
			certbot --email $mail --apache --agree-tos -d $dm >> $insl 2>&1
			(crontab -l 2>/dev/null; echo "0 4 1,15 * * /usr/bin/certbot renew") | crontab -
		fi
		if [ -e $debvf ]
		then
			certbot-3 --non-interactive --email $mail --apache --agree-tos -d $dm >> $insl 2>&1
			(crontab -l 2>/dev/null; echo "0 4 1,15 * * /usr/bin/certbot-3 renew") | crontab -
		fi
		
	fi
fi

if [ -z "$mail" ]
	then
		echo "Skipping adding email address as webmaster inside apache configuration."
	else
		echo "Adding email address as webmaster inside apache configuration."
		echo "Adding email address as webmaster inside apache configuration." >> $insl 2>&1
		if [ -e $debvf ]
		then
			sed -i 's/\bwebmaster@localhost\b/'"$mail"'/g' /etc/apache2/sites-available/nextcloud.conf
		fi
		if [ -e $elvf ]
		then
			sed -i 's/\bwebmaster@localhost\b/'"$mail"'/g' /etc/httpd/conf.d/nextcloud.conf
		fi
fi

# HPB Configuration
# gwaddr=$( route -n | grep 'UG[ \t]' | awk '{print $2}' )
# echo "Enabling HPB" >> $insl 2>&1
# sudo -u $websrv_usr php /var/www/nextcloud/occ app:install notify_push >> $insl 2>&1
# touch /etc/systemd/system/nextcloud_hpb.service
# echo '[Unit]
# Description = Nextcloud High Performance Backend Push Service
# After=redis.service mariadb.service
# 
# [Service]
# Environment = PORT=7867
# ExecStart = /var/www/nextcloud/apps/notify_push/bin/x86_64/notify_push /var/www/nextcloud/config/config.php
# User=$websrv_usr
# 
# [Install]
# WantedBy = multi-user.target
# ' >> /etc/systemd/system/nextcloud_hpb.service
# systemctl enable nextcloud_hpb >> $insl 2>&1
# service nextcloud_hpb start >> $insl 2>&1
# echo -ne '\n' | sudo -u $websrv_usr php /var/www/nextcloud/occ notify_push:setup >> $insl 2>&1
# </root/ips.local awk '{print "sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set trusted_proxies " NR " --value=\x22" $1 "\x22"}' | xargs -L 1 -0  | bash;
# sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set trusted_proxies 97 --value="$gwaddr" >> $insl 2>&1
# sudo -u $websrv_usr php /var/www/nextcloud/occ config:system:set trusted_proxies 98 --value="$addr" >> $insl 2>&1
#if [ $# -eq 0 ]
#then
#	sudo -u $websrv_usr php /var/www/nextcloud/occ notify_push:setup https://$addr/push >> $insl 2>&1
#else
#	sudo -u $websrv_usr php /var/www/nextcloud/occ notify_push:setup https://$1/push >> $insl 2>&1
#fi

# Finished!!!
echo ""
echo "Job done! Now make last steps in Your web browser!"
echo "Use # certbot if You want SSL"
echo ""
if [ -z "$dm" ]
then
	echo "You may access Your Nextcloud instalation using this address:
	http://$addr or
	https://$addr"
else
	echo "You may access Your Nextcloud instalation using this address:
	http://$addr or
	https://$addr or
	https://$dm"
fi

echo "Try to use httpS - there are known Nextcloud problems with Firefox without SSL."
echo ""
echo -e "Here are the important passwords, \e[1;31mbackup them!!!\e[39;0m"
echo "---------------------------------------------------------------------------"
echo -e "Database settings generated are:
login: \e[1;32mnextcloud\e[39;0m
database: \e[1;32mnextdrive\e[39;0m
password: \e[1;32m$mp\e[39;0m"
echo "---------------------------------------------------------------------------"
echo "Preconfigured Nextcloud administration user:"
echo -e "login: \e[38;5;214mSuperAdmin\e[39;0m
password: \e[1;32m$mp2\e[39;0m"
echo "---------------------------------------------------------------------------"
echo "Install finished." >> $insl 2>&1
date >> $insl 2>&1
echo "---------------------------------------------------------------------------" >> $insl 2>&1
rm -rf /root/dbpass
rm -rf /root/superadminpass
rm -rf /root/ips.local
rm -rf /opt/latest.tar.bz2
rm -rf /opt/localhost.crt
rm -rf /opt/localhost.key
rm -rf /opt/nextcloud.crt
rm -rf /opt/nextcloud.key
rm -rf /opt/open_ssl.conf
rm -rf /opt/latest.zip
rm -rf $cdir/latest.zip
rm -rf $cdir/latest.tar.bz2
rm -rf $cdir/ips.local
rm -rf $cdir/superadminpass
rm -rf $cdir/dbpass
rm -rf /var/www/nextcloud/config/autoconfig.php
if [ -e $debvf ]
then
	apt-get autoremove -y >> $insl 2>&1
fi
restart_websrv
touch $ver_file
echo "Version $ver was succesfully installed at $(date +%d-%m-%Y_%H:%M:%S)" >> $ver_file
echo "pver=$ver lang=$lang mail=$mail dm=$dm nv=$nv fdir=$fdir" >> $ver_file
mv $cdir/$scrpt.sh $scrpt-$(date +"%FT%H%M").sh
echo "!!!!!!! Install finished!" >> $insl 2>&1
unset LC_ALL
exit 0

#!/bin/bash

# Nextcloud Debian 11/12 Install Script
# for x86_64
#
# This script is made for Debian 11/12 on AMD64 CPU architecture.
# It will update OS, install neeeded packages, and preconfigure everything to run Nextcloud.
# There are Apache (web server), MariaDB (database server), PHP 8.2 (programming language), 
# NTP (time synchronization service), and Redis (cache server) used.
# Also new service for Nextcloud cron is generated that starts every 5 minutes.
# To use it just download it, make it executable and start with this command:
# sudo sh -c "wget -q https://github.com/nicrame/Linux-Scripts/raw/master/nextcloud-debian-ins.sh && chmod +x nextcloud-debian-ins.sh && ./nextcloud-debian-ins.sh"
# You may also add specific variables (lang, mail, dns) that will be used, by adding them to command above:
# sudo sh -c "wget -q https://github.com/nicrame/Linux-Scripts/raw/master/nextcloud-debian-ins.sh && chmod +x nextcloud-debian-ins.sh && ./nextcloud-debian-ins.sh -lang=pl -mail=my@email.com -dm=domain.com -nv=24"
# -lang (for language) variable will install additional packages specific for choosed language and setup Nextcloud default language.
# Currently supported languages are: none (default value is none/empty that will use web browser language), Arabic (ar), Chinese (zh), French (fr), Hindi (hi), Polish (pl), Spanish (es) and Ukrainian (uk)
# -mail variable is for information about Your email address, that will be presented to let's encrypt, so you'll be informed if domain name SSL certificate couldn't be refreshed (default value is empty).
# -dm variable is used when you got (already prepared and configured) domain name, it will be configured for Nextcloud server and Let's encrypt SSL (default value is empty).
# -nv variable allows You to choose older version to install, supported version are: 24, 25, 26, empty (it will install newest, currently v27)
#
# After install You may use Your web browser to access Nextcloud using local IP address,
# or domain name that You have configured before (DNS setting, router configuration should be done earlier). 
# Both HTTP and HTTPS protocols are enabled by default (localhost certificate is generated
# bu default, and domain certificate with Let's encrypt if You use add it as command variable).
#
# It was tested with Nextcloud v24, v25, v26, v27
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
# V 1.6.2 - 04.08.2023
# - few more languages are now supported with -lang= parameter (Arabic (ar), Chinese (zh), French (fr), Hindi (hi), Spanish (es) and Ukrainian (uk))
# V 1.6.1 - 03.08.2023
# - small tweaks
# V 1.6 - 03.08.2023
# - new variable that allows installing older version of Nextcloud (users reported problems with NC27)
# - the script rename itself after finished work (so installer command always refer to newest version)
# - script is prepared now for few future updates (up to Nextcloud v28)
# V 1.5.5 - 12.07.2023
# - better description of variables use on error.
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
# Currently the way it have to be configured when installing is so unpleasent that this is no go for ordinary users,
# also it don't support dynamic IP's, so it's just useless at some enviroments.

export LC_ALL=C

ver=1.6
cpu=$( uname -m )
user=$( whoami )
debv=$( cat /etc/debian_version )
addr=$( hostname -I )
addr1=$( hostname -I | awk '{print $1}' )
cdir=$( pwd )
lang=""
mail=""
dm=""
nv=""
insl=/var/log/nextcloud-installer.log

while [ "$#" -gt 0 ]; do
    case "$1" in
        -lang=*) lang="${1#*=}" ;;
        -mail=*) mail="${1#*=}" ;;
		-dm=*) dm="${1#*=}" ;;
		-nv=*) nv="${1#*=}" ;;
        *) echo "Unknown parameter: $1" >&2; echo "Remember to add one, or more variables after equals sign."; echo -e "Eg. \e[1;32m-\e[39;0mmail\e[1;32m=\e[39;0mmail@example.com \e[1;32m-\e[39;0mlang\e[1;32m=\e[39;0mpl \e[1;32m-\e[39;0mdm\e[1;32m=\e[39;0mdomain.com \e[1;32m-\e[39;0mnv\e[1;32m=\e[39;024"; exit 1 ;;
    esac
    shift
done

echo -e "\e[38;5;214mNextcloud Debian 11/12 Install Script\e[39;0m
Version $ver for x86_64
by marcin@marcinwilk.eu - www.marcinwilk.eu"
echo "---------------------------------------------------------------------------"

if [ $user != root ]
then
    echo -e "You must be \e[38;5;214mroot\e[39;0m. Mission aborted!"
    echo -e "You are trying to start this script as: \e[1;31m$user\e[39;0m"
    exit 0
fi

if [ -e /var/log/nextcloud-installer.log ]
then
	echo "Nextcloud installer for Debian 11/12 - $ver (www.marcinwilk.eu) started." >> $insl
	date >> $insl
	echo "---------------------------------------------------------------------------" >> $insl
	echo "This script will try to upgrade Nextcloud and all needed services,"
	echo "based on what was done by previous version of this script."
	echo ""
	echo "Trying to find preceding installer version."
	if [ -e /var/local/nextcloud-installer.ver ]
	then
		echo "Detected previous install:"
		pverr1=$(sed -n '1p'  /var/local/nextcloud-installer.ver)
		echo "$pverr1"
		echo "With parameters:"
		pverr2=$(sed -n '2p'  /var/local/nextcloud-installer.ver)
		echo "$pverr2"
		echo ""
        pver=$(echo $pverr2 | awk -F'[ =]' '/pver/ {print $2}')
        lang=$(echo $pverr2 | awk -F'[ =]' '/lang/ {print $4}')
        mail=$(echo $pverr2 | awk -F'[ =]' '/mail/ {print $6}')
        dm=$(echo $pverr2 | awk -F'[ =]' '/dm/ {print $8}')
		nv=$(echo $pverr2 | awk -F'[ =]' '/nv/ {print $10}')
		if [ "$pver" = "1.5" ]
		then
			echo "Detected previous version installer." >> $insl
			echo "$pverr1" >> $insl
			echo "$pverr2" >> $insl
			echo "Version 1.5 installer has been used previously."
			echo "Doing some updates if they are available."
			if [ "$nv" = "24" ]
			then
				echo "Older version of Nextcloud configured, skipping updates and exit."
				echo "Older version of Nextcloud configured, skipping updates and exit." >> $insl
				echo -e "pver=$ver lang=$lang mail=$mail dm=$dm nv=$nv\n$(</var/local/nextcloud-installer.ver)" > /var/local/nextcloud-installer.ver
				echo -e "Version $ver was succesfully installed at $(date +%d-%m-%Y_%H:%M:%S)\n$(</var/local/nextcloud-installer.ver)" > /var/local/nextcloud-installer.ver
				mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
				unset LC_ALL
				exit 0
			fi
			if [ "$nv" = "25" ]
			then
				echo "Older version of Nextcloud configured, skipping updates and exit."
				echo "Older version of Nextcloud configured, skipping updates and exit." >> $insl
				echo -e "pver=$ver lang=$lang mail=$mail dm=$dm nv=$nv\n$(</var/local/nextcloud-installer.ver)" > /var/local/nextcloud-installer.ver
				echo -e "Version $ver was succesfully installed at $(date +%d-%m-%Y_%H:%M:%S)\n$(</var/local/nextcloud-installer.ver)" > /var/local/nextcloud-installer.ver
				mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
				unset LC_ALL
				exit 0
			fi
			if [ "$nv" = "26" ]
			then
				echo "Older version of Nextcloud configured, skipping updates and exit."
				echo "Older version of Nextcloud configured, skipping updates and exit." >> $insl
				echo -e "pver=$ver lang=$lang mail=$mail dm=$dm nv=$nv\n$(</var/local/nextcloud-installer.ver)" > /var/local/nextcloud-installer.ver
				echo -e "Version $ver was succesfully installed at $(date +%d-%m-%Y_%H:%M:%S)\n$(</var/local/nextcloud-installer.ver)" > /var/local/nextcloud-installer.ver
				mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
				unset LC_ALL
				exit 0
			fi
			if [ "$nv" = "27" ]
			then
				echo "Older version of Nextcloud configured, skipping updates and exit."
				echo "Older version of Nextcloud configured, skipping updates and exit." >> $insl
				echo -e "pver=$ver lang=$lang mail=$mail dm=$dm nv=$nv\n$(</var/local/nextcloud-installer.ver)" > /var/local/nextcloud-installer.ver
				echo -e "Version $ver was succesfully installed at $(date +%d-%m-%Y_%H:%M:%S)\n$(</var/local/nextcloud-installer.ver)" > /var/local/nextcloud-installer.ver
				mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
				unset LC_ALL
				exit 0
			fi
			apt-get update >> $insl && apt-get upgrade -y >> $insl && apt-get autoremove -y >> $insl
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "26" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "26" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "26" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "27" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "27" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "27" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "28" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "28" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "28" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			echo -e "pver=$ver lang=$lang mail=$mail dm=$dm nv=$nv\n$(</var/local/nextcloud-installer.ver)" > /var/local/nextcloud-installer.ver
			echo -e "Version $ver was succesfully installed at $(date +%d-%m-%Y_%H:%M:%S)\n$(</var/local/nextcloud-installer.ver)" > /var/local/nextcloud-installer.ver
			echo "Upgrade process finished."
			echo "Job done!"
			mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
			unset LC_ALL
			exit 0
		fi
		if [ "$pver" = "1.6" ]
		then
			echo "Detected same version already used." >> $insl
			echo "$pverr1" >> $insl
			echo "$pverr2" >> $insl
			echo "Same version already used."
			if [ "$nv" = "24" ]
			then
				echo "Older version of Nextcloud configured, skipping updates and exit."
				echo "Older version of Nextcloud configured, skipping updates and exit." >> $insl
				mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
				unset LC_ALL
				exit 0
			fi
			if [ "$nv" = "25" ]
			then
				echo "Older version of Nextcloud configured, skipping updates and exit."
				echo "Older version of Nextcloud configured, skipping updates and exit." >> $insl
				mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
				unset LC_ALL
				exit 0
			fi
			if [ "$nv" = "26" ]
			then
				echo "Older version of Nextcloud configured, skipping updates and exit."
				echo "Older version of Nextcloud configured, skipping updates and exit." >> $insl
				mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
				unset LC_ALL
				exit 0
			fi
			if [ "$nv" = "27" ]
			then
				echo "Older version of Nextcloud configured, skipping updates and exit."
				echo "Older version of Nextcloud configured, skipping updates and exit." >> $insl
				mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
				unset LC_ALL
				exit 0
			fi
			echo "Doing some updates if they are available."
			apt-get update >> $insl && apt-get upgrade -y >> $insl && apt-get autoremove -y >> $insl
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "27" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "27" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "27" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "28" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "28" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			unset ncver
			ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
			if [ "$ncver" = "28" ]
			then
				sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
			fi
			echo "Upgrade process finished."
			echo "Job done!"
			mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
			unset LC_ALL
			exit 0
		fi
	else
		echo "Detected installer version 1.4 or older already used."
		echo "Detected installer version 1.4 or older already used." >> $insl
		echo "Upgrading in progress..."
		echo "Updating OS."
		echo "Updating OS." >> $insl
		apt-get update >> $insl && apt-get upgrade -y >> $insl && apt-get autoremove -y >> $insl
		echo "Installing additional packages."
		apt-get install -y lbzip2 software-properties-common miniupnpc >> $insl
		yes | sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq install ddclient >> $insl
		echo "Installing PHP 8.2"
		apt-get install -y php8.2 libapache2-mod-php8.2 libmagickcore-6.q16-6-extra php8.2-mysql php8.2-common php8.2-redis php8.2-dom php8.2-curl php8.2-exif php8.2-fileinfo php8.2-bcmath php8.2-gmp php8.2-imagick php8.2-mbstring php8.2-xml php8.2-zip php8.2-iconv php8.2-intl php8.2-simplexml php8.2-xmlreader php8.2-ftp php8.2-ssh2 php8.2-sockets php8.2-gd php8.2-imap php8.2-soap php8.2-xmlrpc php8.2-apcu php8.2-dev php8.2-cli >> $insl
		systemctl restart apache2 >> $insl
		echo "Setting up firewall"
		echo "Setting up firewall" >> $insl
		ufw default allow  >> $insl
		ufw --force enable >> $insl
		ufw allow OpenSSH >> $insl
		ufw allow 'WWW Full' >> $insl
		ufw allow 7867/tcp >> $insl
		ufw default deny >> $insl
		ufw show added >> $insl
		echo "OS tweaking for Redis."
		sysctl vm.overcommit_memory=1 >> $insl
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
		echo "PHP config files tweaking."
		echo 'apc.enable_cli=1' >> /etc/php/8.2/cli/conf.d/20-apcu.ini
		sed -i 's/\b128M\b/1024M/g' /etc/php/8.2/apache2/php.ini
		sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' /etc/php/8.2/apache2/php.ini
		sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' /etc/php/8.2/apache2/php.ini
		sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' /etc/php/8.2/apache2/php.ini
		sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' /etc/php/8.2/apache2/php.ini
		sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' /etc/php/8.2/apache2/php.ini
		sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' /etc/php/8.2/apache2/php.ini
		sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' /etc/php/8.2/apache2/php.ini
		sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' /etc/php/8.2/apache2/php.ini
		sed -i '/MySQLi]/amysqli.cache_size = 2000' /etc/php/8.2/apache2/php.ini
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
		echo 'opcache.enable_cli=1' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
		echo 'opcache.interned_strings_buffer=64' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
		echo 'opcache.max_accelerated_files=20000' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
		echo 'opcache.memory_consumption=256' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
		echo 'opcache.save_comments=1' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
		echo 'opcache.enable=1' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
		systemctl restart apache2 >> $insl
		echo "Upgrading Nextcloud." >> $insl
		echo "Upgrading Nextcloud."
		echo "Checking currently installed version." >> $insl
		sudo -u www-data php /var/www/nextcloud/occ config:system:get version >> $insl
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "24" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		unset ncver
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "24" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		unset ncver
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "24" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		unset ncver
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "24" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		unset ncver
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "25" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		unset ncver
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "25" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		unset ncver
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "25" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		unset ncver
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "25" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		unset ncver
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "26" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		unset ncver
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "26" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		unset ncver
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "26" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		unset ncver
		ncver=$( sudo -u www-data php /var/www/nextcloud/occ config:system:get version | awk -F '.' '{print $1}' )
		if [ "$ncver" = "26" ]
		then
			sudo -u www-data php /var/www/nextcloud/updater/updater.phar --no-interaction >> $insl
		fi
		echo ""
		echo ""
		echo "Nextcloud upgraded to version:" >> $insl
		echo "Nextcloud upgraded to version:"
		sudo -u www-data php /var/www/nextcloud/occ config:system:get version >> $insl
		sudo -u www-data php /var/www/nextcloud/occ config:system:get version
		echo "Adding some more Nextcloud tweaks."
		sudo -u www-data php /var/www/nextcloud/occ maintenance:repair >> $insl
		echo ""
		sed -i "/installed' => true,/a\ \ 'htaccess.RewriteBase' => '/'," /var/www/nextcloud/config/config.php
		sudo -u www-data php /var/www/nextcloud/occ maintenance:update:htaccess >> $insl
		sudo -u www-data php /var/www/nextcloud/occ db:add-missing-indices >> $insl
		sudo -u www-data php /var/www/nextcloud/occ db:convert-filecache-bigint --no-interaction >> $insl
		sudo -u www-data php /var/www/nextcloud/occ config:system:set ALLOW_SELF_SIGNED --value="true" >> $insl
		sudo -u www-data php /var/www/nextcloud/occ config:system:set enable_previews --value="true" >> $insl
		sudo -u www-data php /var/www/nextcloud/occ config:system:set preview_max_memory --value="512" >> $insl
		sudo -u www-data php /var/www/nextcloud/occ config:system:set preview_max_x --value="12288" >> $insl
		sudo -u www-data php /var/www/nextcloud/occ config:system:set preview_max_y --value="6912" >> $insl
		sudo -u www-data php /var/www/nextcloud/occ config:system:set auth.bruteforce.protection.enabled --value="true" >> $insl
		sudo -u www-data php /var/www/nextcloud/occ app:install twofactor_totp >> $insl
		sudo -u www-data php /var/www/nextcloud/occ app:enable twofactor_totp >> $insl
		sudo -u www-data php /var/www/nextcloud/occ app:install twofactor_webauthn >> $insl
		sudo -u www-data php /var/www/nextcloud/occ app:enable twofactor_webauthn >> $insl
		sudo -u www-data php /var/www/nextcloud/occ config:app:set files max_chunk_size --value="20971520" >> $insl
		touch /var/local/nextcloud-installer.ver
		echo "Version $ver was succesfully installed at $(date +%d-%m-%Y_%H:%M:%S)" >> /var/local/nextcloud-installer.ver
		echo "pver=$ver lang=$lang mail=$mail dm=$dm" >> /var/local/nextcloud-installer.ver
		echo "Removing PHP 8.1"
		apt-get remove -y php8.1 php8.1-* >> $insl
		echo "Upgrade process finished."
		echo "Job done!"
		mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
		unset LC_ALL
		exit 0
	fi
else
	echo ""
fi

#		echo "Old settings will be used for the upgrade process."
#		echo "You may now cancel this script with CRTL+C,"
#		echo "or wait 35 seconds so it will upgrade old install."

echo "This script will install Nextcloud service."
echo "Additional packages will be installed too:"
echo "Apache, PHP, MariaDB, ddclient and Let's encrypt."
echo ""
echo -e "You may add some variables like -lang=, -mail=, -dm= and nv="
echo "Where lang is for language, supported are: Arabic (ar), Chinese (zh),"
echo "French (fr), Hindi (hi), Polish (pl), Spanish (es) and Ukrainian (uk),"
echo "(empty/undefinied use browser language)."
echo "-mail is for e_mail address of admin, -dm for domain name,"
echo -e "that should be \e[1;32m*preconfigured\e[39;0m,"
echo "and -nv for installing older versions (24, 25, 26 & 27, empty means latest)."
echo ""
echo "./nextcloud-debian-ins.sh -lang=pl -mail=my@email.com -dm=mydomain.com -nv=24"
echo ""
echo "You may now cancel this script with CRTL+C,"
echo "or wait 35 seconds so it will install without"
echo "additional variables."
echo ""
echo -e "\e[1;32m*\e[39;0m - domain and router must be already configured to work with this server."
sleep 36


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
	
if [ ! -f /etc/debian_version ]
then
    echo "Your Linux distribution isn't supported by this script."
    echo "Mission aborted!"
    echo "Unsupported Linux distro!"
    exit 0
else
echo "Detected Debian version $debv"
fi

touch /var/log/nextcloud-installer.log

echo "Nextcloud installer for Debian 11/12 - $ver (www.marcinwilk.eu) started." >> $insl
date >> $insl
echo "---------------------------------------------------------------------------" >> $insl

if [ -z "$lang" ]
then
	echo "No custom language variable used." >> $insl
else
	echo -e "Using language variable: \e[1;32m$lang\e[39;0m"
	echo "Using language variable: $lang" >> $insl
fi

if [ -z "$mail" ]
then
	echo "No e_mail variable used." >> $insl
else
	echo -e "Using e_mail variable: \e[1;32m$mail\e[39;0m"
	echo "Using e_mail variable: $mail" >> $insl
fi

if [ -z "$dm" ]
then
	echo "No custom domain name variable used." >> $insl
else
	echo -e "Using domain variable: \e[1;32m$dm\e[39;0m"
	echo "Using domain variable: $dm" >> $insl
fi

if [ -z "$nv" ]
then
	echo "No older version variable used." >> $insl
else
	echo -e "Using version variable: \e[1;32m$nv\e[39;0m"
	echo "Using version variable: $nv" >> $insl
fi

# Generating passwords for database and SuperAdmin user.
echo "!!!!!!! Generating passwords for database and SuperAdmin user" >> $insl
openssl rand -base64 30 > /root/dbpass
openssl rand -base64 30 > /root/superadminpass
mp=$( cat /root/dbpass )
mp2=$( cat /root/superadminpass )

echo "Updating OS."
echo "!!!!!!! Updating OS" >> $insl
apt-get update >> $insl && apt-get upgrade -y >> $insl && apt-get autoremove -y >> $insl

if [ "$lang" = "ar" ]
then
	echo "!!!!!!! Installing language packages - Arabic" >> $insl
	apt-get install -y task-arabic >> $insl
	localectl set-locale LANG=ar_EG.UTF-8 >> $insl
	locale-gen >> $insl
fi

if [ "$lang" = "zh" ]
then
	echo "!!!!!!! Installing language packages - Chinese" >> $insl
	apt-get install -y task-chinese-s task-chinese-t >> $insl
	localectl set-locale LANG=zh_CN.UTF-8 >> $insl
	locale-gen >> $insl
fi

if [ "$lang" = "fr" ]
then
	echo "!!!!!!! Installing language packages - French" >> $insl
	apt-get install -y task-french >> $insl
	localectl set-locale LANG=fr_FR.UTF-8 >> $insl
	locale-gen >> $insl
fi

if [ "$lang" = "hi" ]
then
	echo "!!!!!!! Installing language packages - Hindi" >> $insl
	apt-get install -y task-hindi >> $insl
	localectl set-locale LANG=hi_IN >> $insl
	locale-gen >> $insl
fi

if [ "$lang" = "pl" ]
then
	echo "!!!!!!! Installing language packages - Polish" >> $insl
	apt-get install -y task-polish >> $insl
	timedatectl set-timezone Europe/Warsaw >> $insl
	localectl set-locale LANG=pl_PL.UTF-8 >> $insl
	locale-gen >> $insl
fi

if [ "$lang" = "es" ]
then
	echo "!!!!!!! Installing language packages - Spanish" >> $insl
	apt-get install -y task-spanish >> $insl
	localectl set-locale LANG=es_ES.UTF-8 >> $insl
	locale-gen >> $insl
fi

if [ "$lang" = "uk" ]
then
	echo "!!!!!!! Installing language packages - Ukrainian" >> $insl
	apt-get install -y task-ukrainian >> $insl
	localectl set-locale LANG=uk_UA.UTF-8 >> $insl
	locale-gen >> $insl
fi

echo "Installing standard packages. It may take some time - be patient."
echo "!!!!!!! Installing standard packages" >> $insl
apt-get install -y git lbzip2 unzip zip lsb-release locales-all rsync wget curl sed screen gawk mc sudo net-tools ethtool vim nano ufw apt-transport-https ca-certificates software-properties-common miniupnpc >> $insl
yes | sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq install ddclient  >> $insl

deb12=$( sudo cat /etc/debian_version | awk -F '.' '{print $1}' )
if [ "$deb12" = "12" ]
then
	apt-get install -y systemd-timesyncd >> $insl
	systemctl enable systemd-timesyncd >> $insl
	systemctl restart systemd-timesyncd >> $insl
else
	apt-get install -y ntp >> $insl
	systemctl enable ntp >> $insl
	systemctl restart ntp >> $insl
fi

echo "Installing web server with PHP."
echo "!!!!!!! Installing web server with PHP" >> $insl
curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg >> $insl
sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' >> $insl
apt-get update >> $insl
apt-get upgrade -y >> $insl
apt-get install -y apache2 apache2-utils >> $insl

if [ "$nv" = "24" ]; then
	echo "Installing PHP version 7.x for Nextcloud v24."
	echo "!!!!!!! Installing PHP version 7.x for Nextcloud v24" >> $insl
	apt-get install -y php7.4 libapache2-mod-php7.4 libmagickcore-6.q16-6-extra php7.4-mysql php7.4-common php7.4-redis php7.4-dom php7.4-curl php7.4-exif php7.4-fileinfo php7.4-bcmath php7.4-gmp php7.4-imagick php7.4-mbstring php7.4-xml php7.4-zip php7.4-iconv php7.4-intl php7.4-simplexml php7.4-xmlreader php7.4-ftp php7.4-ssh2 php7.4-sockets php7.4-gd php7.4-imap php7.4-soap php7.4-xmlrpc php7.4-apcu php7.4-dev php7.4-cli >> $insl
elif [ "$nv" = "25" ]; then
	echo "Installing PHP version 8.1 for Nextcloud v25."
	echo "!!!!!!! Installing PHP version 8.1 for Nextcloud v25" >> $insl
	apt-get install -y php8.1 libapache2-mod-php8.1 libmagickcore-6.q16-6-extra php8.1-mysql php8.1-common php8.1-redis php8.1-dom php8.1-curl php8.1-exif php8.1-fileinfo php8.1-bcmath php8.1-gmp php8.1-imagick php8.1-mbstring php8.1-xml php8.1-zip php8.1-iconv php8.1-intl php8.1-simplexml php8.1-xmlreader php8.1-ftp php8.1-ssh2 php8.1-sockets php8.1-gd php8.1-imap php8.1-soap php8.1-xmlrpc php8.1-apcu php8.1-dev php8.1-cli >> $insl
elif [ "$nv" = "26" ]; then
	echo "Installing PHP version 8.1 for Nextcloud v26."
	echo "!!!!!!! Installing PHP version 8.1 for Nextcloud v26" >> $insl
	apt-get install -y php8.1 libapache2-mod-php8.1 libmagickcore-6.q16-6-extra php8.1-mysql php8.1-common php8.1-redis php8.1-dom php8.1-curl php8.1-exif php8.1-fileinfo php8.1-bcmath php8.1-gmp php8.1-imagick php8.1-mbstring php8.1-xml php8.1-zip php8.1-iconv php8.1-intl php8.1-simplexml php8.1-xmlreader php8.1-ftp php8.1-ssh2 php8.1-sockets php8.1-gd php8.1-imap php8.1-soap php8.1-xmlrpc php8.1-apcu php8.1-dev php8.1-cli >> $insl
elif [ "$nv" = "27" ]; then
	echo "Installing PHP version 8.2 for Nextcloud v27."
	echo "!!!!!!! Installing PHP version 8.2 for Nextcloud v27" >> $insl
	apt-get install -y php8.2 libapache2-mod-php8.2 libmagickcore-6.q16-6-extra php8.2-mysql php8.2-common php8.2-redis php8.2-dom php8.2-curl php8.2-exif php8.2-fileinfo php8.2-bcmath php8.2-gmp php8.2-imagick php8.2-mbstring php8.2-xml php8.2-zip php8.2-iconv php8.2-intl php8.2-simplexml php8.2-xmlreader php8.2-ftp php8.2-ssh2 php8.2-sockets php8.2-gd php8.2-imap php8.2-soap php8.2-xmlrpc php8.2-apcu php8.2-dev php8.2-cli >> $insl
elif [ -z "$nv" ]; then
	echo "Installing newest PHP version for Nextcloud."
	echo "!!!!!!! Installing newest PHP version for Nextcloud" >> $insl
	apt-get install -y php8.2 libapache2-mod-php8.2 libmagickcore-6.q16-6-extra php8.2-mysql php8.2-common php8.2-redis php8.2-dom php8.2-curl php8.2-exif php8.2-fileinfo php8.2-bcmath php8.2-gmp php8.2-imagick php8.2-mbstring php8.2-xml php8.2-zip php8.2-iconv php8.2-intl php8.2-simplexml php8.2-xmlreader php8.2-ftp php8.2-ssh2 php8.2-sockets php8.2-gd php8.2-imap php8.2-soap php8.2-xmlrpc php8.2-apcu php8.2-dev php8.2-cli >> $insl
fi

systemctl restart apache2 >> $insl
systemctl enable apache2 >> $insl
a2dissite 000-default >> $insl

echo "Setting up firewall"
echo "!!!!!!! Setting up firewall" >> $insl
ufw default allow  >> $insl
ufw --force enable >> $insl
ufw allow OpenSSH >> $insl
ufw allow 'WWW Full' >> $insl
ufw allow 7867/tcp >> $insl
ufw default deny >> $insl
ufw show added >> $insl

echo "Simple PHP testing..."
echo "PHP check:" >> $insl
touch test.php
echo '<?php
   echo "PHP is working! \n";
?>' >> test.php
php test.php
php test.php >> $insl
echo '<?php
   phpinfo();
?>' >> info.php
php info.php >> $insl
rm -rf test.php >> $insl
rm -rf info.php >> $insl

echo "Installing cache (redis) and multimedia (ffmpeg) packages."
echo "!!!!!!! Installing cache (redis) and multimedia (ffmpeg) packages" >> $insl
# Tweaks for redis first
sysctl vm.overcommit_memory=1 >> $insl
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
exit 0
" >> /etc/rc.local
chmod +x /etc/rc.local
systemctl daemon-reload
systemctl start rc-local
# REDIS cache configure, adding socket for faster communication on local host
apt-get install -y redis-server >> $insl
sed -i '/# unixsocketperm 700/aunixsocketperm 777' /etc/redis/redis.conf
sed -i '/# unixsocketperm 700/aunixsocket /var/run/redis/redis.sock' /etc/redis/redis.conf
usermod -a -G redis www-data
systemctl restart redis >> $insl

## ffmpeg installing - used for generating thumbnails of video files
apt-get install -y ffmpeg >> $insl

echo "!!!!!!! Configuring PHP options" >> $insl
if [ "$nv" = "24" ]; then
	#Enable APCu command line support
	echo 'apc.enable_cli=1' >> /etc/php/7.4/cli/conf.d/20-apcu.ini

	sed -i 's/\b128M\b/1024M/g' /etc/php/7.4/apache2/php.ini
	sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' /etc/php/7.4/apache2/php.ini
	sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' /etc/php/7.4/apache2/php.ini
	sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' /etc/php/7.4/apache2/php.ini
	sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' /etc/php/7.4/apache2/php.ini
	sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' /etc/php/7.4/apache2/php.ini
	sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' /etc/php/7.4/apache2/php.ini
	sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' /etc/php/7.4/apache2/php.ini
	sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' /etc/php/7.4/apache2/php.ini
	sed -i '/MySQLi]/amysqli.cache_size = 2000' /etc/php/7.4/apache2/php.ini

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

	echo 'opcache.enable_cli=1' >> /etc/php/7.4/apache2/conf.d/10-opcache.ini
	echo 'opcache.interned_strings_buffer=64' >> /etc/php/7.4/apache2/conf.d/10-opcache.ini
	echo 'opcache.max_accelerated_files=20000' >> /etc/php/7.4/apache2/conf.d/10-opcache.ini
	echo 'opcache.memory_consumption=256' >> /etc/php/7.4/apache2/conf.d/10-opcache.ini
	echo 'opcache.save_comments=1' >> /etc/php/7.4/apache2/conf.d/10-opcache.ini
	# echo 'opcache.revalidate_freq=1' >> /etc/php/7.4/apache2/conf.d/10-opcache.ini
	echo 'opcache.enable=1' >> /etc/php/7.4/apache2/conf.d/10-opcache.ini
	# echo 'opcache.jit=disable' >> /etc/php/7.4/apache2/conf.d/10-opcache.inifi
elif [ "$nv" = "25" ]; then
	#Enable APCu command line support
	echo 'apc.enable_cli=1' >> /etc/php/8.1/cli/conf.d/20-apcu.ini

	sed -i 's/\b128M\b/1024M/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' /etc/php/8.1/apache2/php.ini
	sed -i '/MySQLi]/amysqli.cache_size = 2000' /etc/php/8.1/apache2/php.ini

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

	echo 'opcache.enable_cli=1' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	echo 'opcache.interned_strings_buffer=64' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	echo 'opcache.max_accelerated_files=20000' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	echo 'opcache.memory_consumption=256' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	echo 'opcache.save_comments=1' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	# echo 'opcache.revalidate_freq=1' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	echo 'opcache.enable=1' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	# echo 'opcache.jit=disable' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
elif [ "$nv" = "26" ]; then
	#Enable APCu command line support
	echo 'apc.enable_cli=1' >> /etc/php/8.1/cli/conf.d/20-apcu.ini

	sed -i 's/\b128M\b/1024M/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' /etc/php/8.1/apache2/php.ini
	sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' /etc/php/8.1/apache2/php.ini
	sed -i '/MySQLi]/amysqli.cache_size = 2000' /etc/php/8.1/apache2/php.ini

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

	echo 'opcache.enable_cli=1' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	echo 'opcache.interned_strings_buffer=64' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	echo 'opcache.max_accelerated_files=20000' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	echo 'opcache.memory_consumption=256' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	echo 'opcache.save_comments=1' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	# echo 'opcache.revalidate_freq=1' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	echo 'opcache.enable=1' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
	# echo 'opcache.jit=disable' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
elif [ "$nv" = "27" ]; then
	#Enable APCu command line support
	echo 'apc.enable_cli=1' >> /etc/php/8.2/cli/conf.d/20-apcu.ini

	sed -i 's/\b128M\b/1024M/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' /etc/php/8.2/apache2/php.ini
	sed -i '/MySQLi]/amysqli.cache_size = 2000' /etc/php/8.2/apache2/php.ini

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

	echo 'opcache.enable_cli=1' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	echo 'opcache.interned_strings_buffer=64' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	echo 'opcache.max_accelerated_files=20000' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	echo 'opcache.memory_consumption=256' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	echo 'opcache.save_comments=1' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	# echo 'opcache.revalidate_freq=1' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	echo 'opcache.enable=1' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	# echo 'opcache.jit=disable' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
elif [ -z "$nv" ]; then
	#Enable APCu command line support
	echo 'apc.enable_cli=1' >> /etc/php/8.2/cli/conf.d/20-apcu.ini

	sed -i 's/\b128M\b/1024M/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 3600/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bmax_input_time = 60\b/max_input_time = 3600/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16G/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16G/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' /etc/php/8.2/apache2/php.ini
	sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 3600/g' /etc/php/8.2/apache2/php.ini
	sed -i '/MySQLi]/amysqli.cache_size = 2000' /etc/php/8.2/apache2/php.ini

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

	echo 'opcache.enable_cli=1' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	echo 'opcache.interned_strings_buffer=64' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	echo 'opcache.max_accelerated_files=20000' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	echo 'opcache.memory_consumption=256' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	echo 'opcache.save_comments=1' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	# echo 'opcache.revalidate_freq=1' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	echo 'opcache.enable=1' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
	# echo 'opcache.jit=disable' >> /etc/php/8.2/apache2/conf.d/10-opcache.ini
fi
echo "!!!!!!! Creating certificates for localhost and vhost" >> $insl
# Creating certificate for localhost
cd /opt/
touch open_ssl.conf
echo '[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = PL
ST = Internet
L = Unknown
O = Nextcloud
OU = NAS
CN = Nextcloud Drive
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
DNS.2 = local' >> open_ssl.conf
# echo '' >> open_ssl.conf
openssl req -x509 -nodes -days 4096 -newkey rsa:2048 -keyout localhost.key -out localhost.crt -config open_ssl.conf -extensions 'v3_req' >> $insl
cp localhost.crt /etc/ssl/certs/localhost.crt >> $insl
# mkdir /etc/ssl/private/
cp localhost.key /etc/ssl/private/localhost.key >> $insl

# Creating VHost for Apache
echo '<VirtualHost *:80>
  ServerAdmin webmaster@localhost
  # ServerName localhost
  DocumentRoot /var/www/nextcloud
  
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
  SSLCertificateFile      /etc/ssl/certs/localhost.crt
  SSLCertificateKeyFile /etc/ssl/private/localhost.key
</VirtualHost>
' > /etc/apache2/sites-available/nextcloud.conf

a2enmod ssl >> $insl
a2enmod rewrite >> $insl
a2enmod headers >> $insl
a2enmod env >> $insl
a2enmod dir >> $insl
a2enmod mime >> $insl
a2enmod proxy >> $insl
# a2enmod proxy_http >> $insl
# a2enmod proxy_wstunnel >> $insl
a2ensite nextcloud.conf >> $insl

echo "Installing MariaDB database server."
echo "!!!!!!! Installing MariaDB database server" >> $insl
apt-get install -y mariadb-server >> $insl

# Adding MariaDB options
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

systemctl enable mariadb >> $insl
systemctl restart mariadb >> $insl

# MariaDB Installed Snapshot

# Make sure that NOBODY can access the server without a password
mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$mp');" >> $insl
# Kill the anonymous users
# mysql -e "DROP USER ''@'localhost'" >> $insl
# Because our hostname varies we'll use some Bash magic here.
# mysql -e "DROP USER ''@'$(hostname)'" >> $insl
# Disable remote root user access
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')" >> $insl
# Kill off the demo database

# Creating database for Nextcloud
mysql -e "SET GLOBAL innodb_default_row_format='dynamic'" >> $insl
mysql -e "CREATE DATABASE nextdrive CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci" >> $insl
mysql -e "GRANT ALL on nextdrive.* to 'nextcloud'@'%' identified by '$mp'" >> $insl

# Make our changes take effect
mysql -e "FLUSH PRIVILEGES" >> $insl

# Importing data into database: enabling smb share in nextcloud, enabling plugins if needed.
# Export cmd: mysqldump -u root -p --all-databases --skip-lock-tables > alldb.sql

# Downloading and installing Let's encrypt mechanism
apt-get install -y python3-certbot-apache >> $insl

# Downloading and installing Nextcloud
echo "!!!!!!! Downloading and installing Nextcloud" >> $insl
mkdir /var/www/nextcloud
mkdir /var/www/nextcloud/data
if [ -e latest.zip ]
then
	mv latest.zip $(date +"%FT%H%M")-latest.zip >> $insl
fi

if [ "$nv" = "24" ]; then
	echo "Downloading and unpacking Nextcloud v$nv." >> $insl
	wget -q https://download.nextcloud.com/server/releases/nextcloud-24.0.12.zip >> $insl
	mv nextcloud-24.0.12.zip latest.zip >> $insl
elif [ "$nv" = "25" ]; then
	echo "Downloading and unpacking Nextcloud v$nv." >> $insl
	wget -q https://download.nextcloud.com/server/releases/nextcloud-25.0.9.zip >> $insl
	mv nextcloud-25.0.9.zip latest.zip >> $insl
elif [ "$nv" = "26" ]; then
	echo "Downloading and unpacking Nextcloud v$nv." >> $insl
	wget -q https://download.nextcloud.com/server/releases/nextcloud-26.0.4.zip >> $insl
	mv nextcloud-26.0.4.zip latest.zip >> $insl
elif [ "$nv" = "27" ]; then
	echo "Downloading and unpacking Nextcloud v$nv." >> $insl
	wget -q https://download.nextcloud.com/server/releases/nextcloud-27.0.1.zip >> $insl
	mv nextcloud-27.0.1.zip latest.zip >> $insl
fi

if [ -e latest.zip ]
then
	unzip -q latest.zip -d /var/www >> $insl
else
	wget -q https://download.nextcloud.com/server/releases/latest.zip >> $insl
	unzip -q latest.zip -d /var/www >> $insl
fi

chown -R www-data:www-data /var/www/

# Making Nextcloud preconfiguration
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

sudo -u www-data php /var/www/nextcloud/occ maintenance:install --database \
"mysql" --database-name "nextdrive"  --database-user "nextcloud" --database-pass \
"$mp" --admin-user "SuperAdmin" --admin-pass "$mp2" >> $insl

if [ "$lang" = "ar" ]
then
	sudo -u www-data php /var/www/nextcloud/occ config:system:set default_language --value="ar" >> $insl
fi

if [ "$lang" = "zh" ]
then
	sudo -u www-data php /var/www/nextcloud/occ config:system:set default_language --value="zh" >> $insl
fi

if [ "$lang" = "fr" ]
then
	sudo -u www-data php /var/www/nextcloud/occ config:system:set default_language --value="fr" >> $insl
fi

if [ "$lang" = "hi" ]
then
	sudo -u www-data php /var/www/nextcloud/occ config:system:set default_language --value="hi" >> $insl
fi

if [ "$lang" = "pl" ]
then
	# Adding default language and locales
	#  'default_language' => 'pl',
	#  'default_locale' => 'pl',
	sudo -u www-data php /var/www/nextcloud/occ config:system:set default_language --value="pl" >> $insl
	sudo -u www-data php /var/www/nextcloud/occ config:system:set default_locale --value="pl_PL" >> $insl
	sudo -u www-data php /var/www/nextcloud/occ config:system:set default_phone_region --value="PL" >> $insl
fi

if [ "$lang" = "es" ]
then
	sudo -u www-data php /var/www/nextcloud/occ config:system:set default_language --value="es" >> $insl
fi

if [ "$lang" = "uk" ]
then
	sudo -u www-data php /var/www/nextcloud/occ config:system:set default_language --value="uk" >> $insl
fi

# Enabling Redis in config file - default cache engine now
sed -i "/installed' => true,/a\ \ 'memcache.local' => '\\\OC\\\Memcache\\\Redis',\n\ \ 'filelocking.enabled' => true,\n \ 'memcache.locking' => '\\\OC\\\Memcache\\\Redis',\n \ 'memcache.distributed' => '\\\OC\\\Memcache\\\Redis',\n \ 'redis' =>\n \ array (\n \  \ 'host' => '/var/run/redis/redis.sock',\n \  \ 'port' => 0,\n \  \ 'dbindex' => 0,\n \  \ 'timeout' => 600.0,\n \ )," /var/www/nextcloud/config/config.php

# APCu cacheing
# sed -i "/installed' => true,/a\ \ 'memcache.local' => '\\\OC\\\Memcache\\\APCu'," /var/www/nextcloud/config/config.php

# Disabling info about creating free account on shared pages/links when logged out (because it is missleading for private nextcloud instances).
sed -i "/installed' => true,/a\ \ 'simpleSignUpLink.shown' => false," /var/www/nextcloud/config/config.php

# Command below should do nothing, but once in the past i needed that, so let it stay here...
sudo -u www-data php /var/www/nextcloud/occ db:add-missing-indices >> $insl

# Enabling plugins. Adding more trusted domains.
# Preparing list of local IP addresses to add.
hostname -I | xargs -n1 >> /root/ips.local

</root/ips.local awk '{print "sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains " NR " --value=\x22" $1 "\x22"}' | xargs -L 1 -0  | bash;
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 97 --value="127.0.0.1" >> $insl
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 98 --value="nextdrive" >> $insl
sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 99 --value="nextcloud" >> $insl
sudo -u www-data php /var/www/nextcloud/occ config:system:set ALLOW_SELF_SIGNED --value="true" >> $insl
sudo -u www-data php /var/www/nextcloud/occ config:system:set enable_previews --value="true" >> $insl
sudo -u www-data php /var/www/nextcloud/occ config:system:set preview_max_memory --value="512" >> $insl
sudo -u www-data php /var/www/nextcloud/occ config:system:set preview_max_x --value="12288" >> $insl
sudo -u www-data php /var/www/nextcloud/occ config:system:set preview_max_y --value="6912" >> $insl
sudo -u www-data php /var/www/nextcloud/occ config:system:set auth.bruteforce.protection.enabled --value="true" >> $insl
mkdir /var/www/nextcloud/core/.null >> $insl
sudo -u www-data php /var/www/nextcloud/occ config:system:set skeletondirectory --value="core/.null" >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:install contacts >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:install notes >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:install deck >> $insl
# sudo -u www-data php /var/www/nextcloud/occ app:install spreed >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:install calendar >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:enable calendar >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:install files_rightclick >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:enable files_rightclick >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:disable updatenotification >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:enable tasks >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:enable groupfolders >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:install twofactor_totp >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:enable twofactor_totp >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:install twofactor_webauthn >> $insl
sudo -u www-data php /var/www/nextcloud/occ app:enable twofactor_webauthn >> $insl
sudo -u www-data php /var/www/nextcloud/occ config:app:set files max_chunk_size --value="20971520" >> $insl

# Below lines will give more data if something goes wrong!
curl -I http://127.0.0.1/  >> $insl
cat /var/www/nextcloud/data/nextcloud.log >> $insl

# Disable .htaccess blocking because we use nginx that do not use it, also it should be handled by Nextcloud itself!
# sed -i "/CONFIG = array (/a\ \ 'blacklisted_files' => array()," /var/www/nextcloud/config/config.php

systemctl stop apache2
# Another lines that helped me in the past are here to stay...
# sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on >> $insl
sudo -u www-data php /var/www/nextcloud/occ db:convert-filecache-bigint --no-interaction >> $insl
# sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off >> $insl

# Preparing cron service to run cron.php every 5 minute
touch /etc/systemd/system/nextcloudcron.service
touch /etc/systemd/system/nextcloudcron.timer

echo '[Unit]' >> /etc/systemd/system/nextcloudcron.service
echo 'Description=Nextcloud cron.php job' >> /etc/systemd/system/nextcloudcron.service
echo '' >> /etc/systemd/system/nextcloudcron.service
echo '[Service]' >> /etc/systemd/system/nextcloudcron.service
echo 'User=www-data' >> /etc/systemd/system/nextcloudcron.service
echo 'ExecStart=php8.2 -f /var/www/nextcloud/cron.php' >> /etc/systemd/system/nextcloudcron.service
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

systemctl start nextcloudcron.timer
systemctl enable nextcloudcron.timer
systemctl restart apache2

#Additional things that may fix some unknown Nextcloud problems (that appeared for me when started using v19)
chown -R www-data:www-data /var/www/nextcloud
chmod 775 /var/www/nextcloud

sudo -u www-data php /var/www/nextcloud/occ maintenance:repair >> $insl

sudo -u www-data php /var/www/nextcloud/occ files:scan-app-data >> $insl
sudo -u www-data php /var/www/nextcloud/occ files:scan --all; >> $insl
sudo -u www-data php /var/www/nextcloud/occ files:cleanup; >> $insl
# sudo -u www-data php /var/www/nextcloud/occ preview:generate-all -vvv

# hide index.php from urls
sed -i "/installed' => true,/a\ \ 'htaccess.RewriteBase' => '/'," /var/www/nextcloud/config/config.php
sudo -u www-data php /var/www/nextcloud/occ maintenance:update:htaccess >> $insl

echo "Using UPNP to open ports for now." >> $insl
upnpc -e "Web Server HTTP" -a $addr1 80 80 TCP >> $insl 2>&1
upnpc -e "Web Server HTTPS" -a $addr1 443 443 TCP >> $insl 2>&1

if [ -z "$dm" ]
then
	echo "Skipping additional domain configuration."
else
	echo "Configuring additional domain name."
	echo "!!!!!!! Configuring additional domain name" >> $insl
	sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 96 --value="$dm" >> $insl
	sed -i '/ServerName localhost/aServerName '"$dm"'' /etc/apache2/sites-available/nextcloud.conf >> $insl
	echo "Configuring Let's encrypt."
	if [ -z "$mail" ]
	then
		echo "Skipping adding email configuration for Let's encrypt."
		certbot --register-unsafely-without-email --apache --agree-tos -d $dm >> $insl
		(crontab -l 2>/dev/null; echo "0 4 1,15 * * /usr/bin/certbot renew") | crontab -
	else
		certbot --email $mail --apache --agree-tos -d $dm >> $insl
		(crontab -l 2>/dev/null; echo "0 4 1,15 * * /usr/bin/certbot renew") | crontab -
	fi
fi

# HPB Configuration
# gwaddr=$( route -n | grep 'UG[ \t]' | awk '{print $2}' )
# echo "Enabling HPB" >> $insl
# sudo -u www-data php /var/www/nextcloud/occ app:install notify_push >> $insl
# touch /etc/systemd/system/nextcloud_hpb.service
# echo '[Unit]
# Description = Nextcloud High Performance Backend Push Service
# After=redis.service mariadb.service
# 
# [Service]
# Environment = PORT=7867
# ExecStart = /var/www/nextcloud/apps/notify_push/bin/x86_64/notify_push /var/www/nextcloud/config/config.php
# User=www-data
# 
# [Install]
# WantedBy = multi-user.target
# ' >> /etc/systemd/system/nextcloud_hpb.service
# systemctl enable nextcloud_hpb >> $insl
# service nextcloud_hpb start >> $insl
# echo -ne '\n' | sudo -u www-data php /var/www/nextcloud/occ notify_push:setup >> $insl
# </root/ips.local awk '{print "sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_proxies " NR " --value=\x22" $1 "\x22"}' | xargs -L 1 -0  | bash;
# sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_proxies 97 --value="$gwaddr" >> $insl
# sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_proxies 98 --value="$addr" >> $insl
#if [ $# -eq 0 ]
#then
#	sudo -u www-data php /var/www/nextcloud/occ notify_push:setup https://$addr/push >> $insl
#else
#	sudo -u www-data php /var/www/nextcloud/occ notify_push:setup https://$1/push >> $insl
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
echo "Install finished." >> $insl
date >> $insl
echo "---------------------------------------------------------------------------" >> $insl
rm -rf /root/dbpass
rm -rf /root/superadminpass
rm -rf /root/ips.local
rm -rf /opt/latest.tar.bz2
rm -rf /opt/localhost.crt
rm -rf /opt/localhost.key
rm -rf /opt/open_ssl.conf
apt-get autoremove -y >> $insl
systemctl restart apache2
touch /var/local/nextcloud-installer.ver
echo "Version $ver was succesfully installed at $(date +%d-%m-%Y_%H:%M:%S)" >> /var/local/nextcloud-installer.ver
echo "pver=$ver lang=$lang mail=$mail dm=$dm nv=$nv" >> /var/local/nextcloud-installer.ver
mv $cdir/nextcloud-debian-ins.sh nextcloud-debian-ins-$(date +"%FT%H%M").sh
unset LC_ALL
exit 0

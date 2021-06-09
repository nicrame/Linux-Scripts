#!/bin/bash

# LAMP install script for EL (versions 8)
# Version 1.2 for x86_64
#
# More info:
# [PL/ENG] https://www.marcinwilk.eu/projects/skrypt-centos-8-lamp/
#
# This script use Remi's repo for PHP packages.
# Please support Remi by donations at https://rpms.remirepo.net/ !!!!
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
# v 1.2 - 09.06.2021
# Use MariaDB from OS repo as default install source.
# Fixed some PowerTools installer (name has changed in repos).
# Initial Let's Encrypt certbot (SSL) integration.
# Tested on RockyLinux 8!
# v 1.1 - 17.09.2020
# Show summary.
# Adminer is used as default database web administration panel.
# Add phpdet.php file to check if PHP is working.
# Add vsftpd as FTP server.
# v 1.0 - 14.09.2020
# First version, tested on CentOS 8.
#
# run script with:
# dnf -y install wget ; rm -rf centos-lamp.sh ; wget marcinwilk.eu/centos-lamp.sh ; chmod +x centos-lamp.sh ; ./centos-lamp.sh

# ############################################### Configuration ##############################################################
#
# You may choose installing Apache(httpd) web server or nginx(nginx). Apache is default. 
webserver=httpd
# Replace CentOS default php version with remi(remi), or install it as secondary version(second). Second method is default.
php=second
# Install MariaDB from default OS repo(repodb), or use MariaDB repo(mariadb). OS repo is default.
mariadb=repodb
# ############################################### Configuration ##############################################################

user=$(whoami)
# User name that run the script. No reasons to change it.
# Used only for testing.

el5=$( cat /etc/redhat-release | grep "release 5" )
el6=$( cat /etc/redhat-release | grep "release 6" )
el7=$( cat /etc/redhat-release | grep "release 7" )
el8=$( cat /etc/redhat-release | grep "release 8" )

echo -e "Welcome in \e[93mLAMP install script \e[39mfor CentOS."
echo -e "Version \e[91m1.1 \e[39msupporting CentOS version 8."
echo ""
echo "This script will install additional software and will make changes"
echo "in system config files so web server with PHP and database will be ready to use."
echo ""
echo "Changes in the system:"
echo "1. Checking user that runs script and OS version."
echo "2. Disabling SELinux, add EPEL and Remi's repo, installing packages, configuring services and firewall."
echo ""
echo -e "\e[93mIMPORTANT\e[39m: Edit this script file to configure web server: apache(default) or nginx,"
echo "PHP running method: multipackage(default) using own directory, or as OS standard,"
echo "database: use older MariaDB from OS repo(default), or newer from MariaDB's repo."
echo ""
echo "To stop now and configure use CTRL+C,"
sleep 20

if [ $user != root ]
then
    echo "You must be root. Mission aborted!"
    echo "You are trying to start this script as: $user"
    exit 0
else
    echo "You are root, this is good for me..."
fi
echo "------------------- ---------- -------- ----- -"

if [ -n "$el5" ]
then
	echo "Too old CentOS version. Pleasu upgrade to CentOS 8."
	echo "Mission aborted!."
exit 0
fi

if [ -n "$el6" ]
then
	echo "Too old CentOS version. Pleasu upgrade to CentOS 8."
	echo "Mission aborted!."
	exit 0
fi

if [ -n "$el7" ]
then
	echo "Too old CentOS version. Pleasu upgrade to CentOS 8."
	echo "Mission aborted!."
	exit 0
fi

echo "This process will take some time, please be patient..."
if [ ! -f /etc/redhat-release ]
then
    echo "Your Linux distribution isn't supported by this script."
    echo "Mission aborted!"
    exit 0
fi

# Disabling SELinux problems
echo "Disabling SELinux."
setenforce 0
sed --in-place=.bak 's/^SELINUX\=enforcing/SELINUX\=disabled/g' /etc/selinux/config
echo "Add EPEL repo, enable PowerTools packages, installing chrony NTP client, curl, vim, vsftpd, wget, ImageMagick and lynx."
dnf -y -d0 install --nogpgcheck https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf config-manager -q --enable PowerTools
dnf config-manager -q --set-enabled powertools
dnf -y -d0 install yum-utils chrony curl vim vsftpd lynx wget ImageMagick
dnf -y -d0 update

hostname=$(hostname)
ipaddr=$(hostname -I)
ipext=$(curl -s https://ipecho.net/plain)

systemctl --now enable chronyd

# Setting up firewall
echo "Configuring firewall and SELinux policies if someone want to enable it again."
firewall-cmd --add-service=http --zone=public --permanent
firewall-cmd --add-service=https --zone=public --permanent
firewall-cmd --add-service=ftp --zone=public --permanent
firewall-cmd --reload
setsebool -P ftpd_full_access on 
setsebool -P httpd_can_network_connect on

systemctl --now enable vsftpd

echo "Installing web server."
if [ $webserver = httpd ]
then
	dnf -y -d0 install httpd
	systemctl --now enable httpd
	echo "At this pont default html website is stored in /var/www/html and server is working."
else
	dnf -y -d0 install nginx	
	systemctl --now enable nginx
	echo "At this pont default html website is stored in /usr/share/nginx/html and server is working."
fi

echo "Installing and configuring PHP."
if [ $php = second ]
then
	dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
	dnf -y install php74
	dnf -y install php74-php-fpm php74-php-mysql php74-php-pear php74-php-mysqlnd php74-php-pecl-zip php74-php-bcmath php74-php-xml php74-php-mbstring php74-php-gd php74-php-intl php74-php-process php74-php-imap php74-php-gmp php74-php-pecl-mcrypt php74-php-smbclient php74-php-imagick php74-php-pdo php74-php-recode php74-php-xmlrpc php74-php-pecl-lzf php74-php-zstd php74-php-geos php74-php-opcache
	dnf -y install php74-php-phpiredis php74-php-pecl-redis5 hiredis php74-php-pecl-apcu

	#Enable APCu command line support
	sed -i '/apc.enable_cli=0/aapc.enable_cli=1' /etc/opt/remi/php74/php.d/40-apcu.ini

	systemctl --now enable php74-php-fpm
	php74 --version
	echo "PHP is installed now and running as php74-php-fpm service. You may also use php74 command from terminal."
		if [ $webserver = httpd ]
		then
		touch /var/www/html/phpdet.php
		echo '<?php' >> /var/www/html/phpdet.php
		echo 'phpinfo();' >> /var/www/html/phpdet.php
		echo '?>' >> /var/www/html/phpdet.php
		chown -R apache:apache /var/www/html/phpdet.php
		systemctl restart httpd
		else
		touch /etc/nginx/conf.d/php74-php-fpm.conf
		echo "upstream php74-php-fpm {" >> /etc/nginx/conf.d/php74-php-fpm.conf
		echo "server unix:/var/opt/remi/php74/run/php-fpm/www.sock;" >> /etc/nginx/conf.d/php74-php-fpm.conf
		echo "}" >> /etc/nginx/conf.d/php74-php-fpm.conf
		chown -R nginx:nginx /etc/nginx/conf.d/php74-php-fpm.conf
		touch /etc/nginx/default.d/php74-fpm.conf
		echo 'index index.php index.html index.htm;' >> /etc/nginx/default.d/php74-fpm.conf
		echo '' >> /etc/nginx/default.d/php74-fpm.conf
		echo 'location ~ \.php$ {' >> /etc/nginx/default.d/php74-fpm.conf
		echo 'try_files $uri =404;' >> /etc/nginx/default.d/php74-fpm.conf
		echo 'fastcgi_intercept_errors on;' >> /etc/nginx/default.d/php74-fpm.conf
		echo 'fastcgi_index  index.php;' >> /etc/nginx/default.d/php74-fpm.conf
		echo 'include        fastcgi_params;' >> /etc/nginx/default.d/php74-fpm.conf
		echo 'fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;' >> /etc/nginx/default.d/php74-fpm.conf
		echo 'fastcgi_pass   php74-php-fpm;' >> /etc/nginx/default.d/php74-fpm.conf
		echo '}' >> /etc/nginx/default.d/php74-fpm.conf
		chown -R nginx:nginx /etc/nginx/default.d/php74-fpm.conf
		sed -i 's/\bapache\b/nginx/g' /etc/opt/remi/php74/php-fpm.d/www.conf
		touch /usr/share/nginx/html/phpdet.php
		echo '<?php' >> /usr/share/nginx/html/phpdet.php
		echo 'phpinfo();' >> /usr/share/nginx/html/phpdet.php
		echo '?>' >> /usr/share/nginx/html/phpdet.php
		chown -R nginx:nginx /usr/share/nginx/html/phpdet.php
		chown -R nginx:nginx /var/opt/remi/php74/lib/php
		echo "Installing incron to check /var/lib/php owner coz it change when php is upgraded breaking nginx."
		dnf -y -d0 install incron vim
		touch /var/spool/incron/root
		echo '/opt/remi/php74/root/usr/bin/php    IN_MODIFY       chown -R nginx:nginx /var/opt/remi/php74/lib/php' >> /var/spool/incron/root
		systemctl --now enable incrond
		systemctl restart php74-php-fpm
		systemctl restart nginx
		fi
else
	dnf -y -d0 install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
	dnf -y -d0 module reset php
	dnf -y -d0 module install php:remi-7.4
	dnf -y -d0 update
	dnf -y -d0 install php-mysql php-mysqlnd php-pecl-zip php-bcmath php-xml php-mbstring php-gd php-fpm php-intl php-process php-imap php-gmp php-pecl-mcrypt php-smbclient php-imagick php-pdo php-recode php-xmlrpc php-pecl-lzf php-zstd php-geos php-opcache
	dnf -y -d0 install php-phpiredis php-pecl-redis5 hiredis php-pecl-apcu

	#Enable APCu command line support
	sed -i '/apc.enable_cli=0/aapc.enable_cli=1' /etc/php.d/40-apcu.ini

	systemctl --now enable php-fpm
	php --version
	echo "PHP is installed now and running as php-fpm service. You may also use php command from terminal."
	if [ $webserver = httpd ]
	then
	touch /var/www/html/phpdet.php
	echo '<?php' >> /var/www/html/phpdet.php
	echo 'phpinfo();' >> /var/www/html/phpdet.php
	echo '?>' >> /var/www/html/phpdet.php
	chown -R apache:apache /var/www/html/phpdet.php
	systemctl restart httpd
	else
	chmod 777 /var/lib/php
	chmod 777 /var/lib/php/session
	mkdir /var/lib/php/opcache
	chmod 777 /var/lib/php/opcache
	chmod 777 /var/lib/php/wsdlcache
	chown -R nginx:nginx /var/lib/php
	sed -i 's/\bapache\b/nginx/g' /etc/php-fpm.d/www.conf
	mkdir /run/php-fpm
	chmod 777 /run/php-fpm
	chown -R nginx:nginx /run/php-fpm
	sed -i 's/\blisten.acl_users = nginx,nginx\b/listen.acl_users = apache,nginx/g' /etc/php-fpm.d/www.conf
	touch /usr/share/nginx/html/phpdet.php
	echo '<?php' >> /usr/share/nginx/html/phpdet.php
	echo 'phpinfo();' >> /usr/share/nginx/html/phpdet.php
	echo '?>' >> /usr/share/nginx/html/phpdet.php
	chown -R nginx:nginx /usr/share/nginx/html/phpdet.php
	systemctl restart nginx
	echo "Installing incron to check /var/lib/php owner coz it change when php is upgraded breaking nginx."
	dnf -y -d0 install incron vim
	touch /var/spool/incron/root
	echo '/usr/bin/php    IN_MODIFY       chown -R nginx:nginx /var/lib/php' >> /var/spool/incron/root
	systemctl --now enable incrond
	fi
fi

#LE
echo "Installing Let's Encrypt certbot software that You may like to use for SSL generation purpose later."
dnf install certbot mod_ssl -y -d0

echo "Generating DHParam 2048 bit key."
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

echo "Creating default Let's Encrypt directory location for refreshing certificates of every vhost."
mkdir -p /var/lib/letsencrypt/.well-known
chgrp apache /var/lib/letsencrypt
chmod g+s /var/lib/letsencrypt
touch /etc/httpd/conf.d/letsencrypt.conf
echo 'Alias /.well-known/acme-challenge/ "/var/lib/letsencrypt/.well-known/acme-challenge/"
<Directory "/var/lib/letsencrypt/">
    AllowOverride None
    Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
    Require method GET POST OPTIONS
</Directory>' >> /etc/httpd/conf.d/letsencrypt.conf

touch /etc/httpd/conf.d/ssl-params.conf
echo 'SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSLHonorCipherOrder On
# Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
Header always set X-Frame-Options SAMEORIGIN
Header always set X-Content-Type-Options nosniff
# Requires Apache >= 2.4
SSLCompression off
SSLUseStapling on
SSLStaplingCache "shmcb:logs/stapling-cache(150000)"
# Requires Apache >= 2.4.11
SSLSessionTickets Off' >> /etc/httpd/conf.d/ssl-params.conf

echo "Installing database."
if [ $mariadb = repodb ]
then
	dnf -y -d0 install mariadb-server
	systemctl --now enable mariadb
	echo "MariaDB from main repo is now installed."
else
	cd /tmp
	wget -q https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
	chmod +x mariadb_repo_setup
	./mariadb_repo_setup
	dnf -y -d0 install perl-DBI libaio libsepol lsof boost-program-options rsync
	dnf check
	dnf -y -d0 module enable perl:5.26
	dnf -y -d0 install --repo="mariadb-main" MariaDB-server
	rm -rf mariadb_repo_setup
	mkdir /var/log/mysql
	chmod 777 /var/log/mysql
	systemctl --now enable mariadb
	mysql_upgrade
	echo "MariaDB from it's own repo is now installed."
fi

echo "- -- --- ------------------------- WARNING !!!! ------------------------- --- -- -"
echo "Now MariaDB wizard will be started to make it secure. Please answer some questions."
echo "Currently there is no database password - so hit enter on question:"
echo "Enter current password for root (enter for none):"
echo ""
sleep 5
mysql_secure_installation

echo "Installing database administration package."
cd /tmp
wget -q https://github.com/vrana/adminer/releases/download/v4.7.7/adminer-4.7.7.php
if [ $webserver = httpd ]
then
	mkdir /var/www/html/db-adm/
	mv /tmp/adminer-4.7.7.php /var/www/html/db-adm/index.php
	chown -R apache:apache /var/www/html/db-adm
else
	mkdir /usr/share/nginx/html/db-adm/
	mv /tmp/adminer-4.7.7.php /usr/share/nginx/html/db-adm/index.php
	chown -R nginx:nginx /usr/share/nginx/html/db-adm
fi
sleep 5
clear
echo "You may access Your services (www, ftp) using your local ip 127.0.0.1, or your hostname that is $hostname,"
echo "or Your local IP that is $ipaddr, or eternal IP if access is possible: $ipext."
echo ""
echo "Your default www location is:"
if [ $webserver = httpd ]
then
	echo "/var/www/html/"
	echo "Default Adminer (database administration website) location is:"
	echo "/var/www/html/db-adm"
else
	echo "/usr/share/nginx/html"
	echo "Default Adminer (database administration website) location is:"
	echo "/usr/share/nginx/html/db-adm"
fi
echo ""
echo "Here are examples of link to access services installed:"
echo -e "Main website:     --- Database Administration:     --- PHP info script:     "
echo "http://127.0.0.1 --- http://127.0.0.1/db-adm/ --- http://127.0.0.1/phpdet.php"
echo "http://$hostname --- http://$hostname/db-adm/ --- http://$hostname/phpdet.php"
echo "http://$ipaddr --- http://$ipaddr/db-adm/ --- http://$ipaddr/phpdet.php"
echo "http://$ipext --- http://$ipext/db-adm/ --- http://$ipext/phpdet.php"
echo ""
echo "Remember, if You want to serve web space for users, public_html directories must be created for each user, then chmod 711 /home/username directory and chmod 755 /home/username/public_html directory."
echo "You will also have to enable it on your own in web server configuration (it is much easier and almost ready in Apache)."
echo "FTP access must be configured before use, but service is up and running."
echo ""
echo "Everything is ready now, have fun!"

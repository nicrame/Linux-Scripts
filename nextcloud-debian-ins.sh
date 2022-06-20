#!/bin/bash

# Nextcloud Debian 11 Install Script
# Version 1.0 for x86_64
#
# This script is made for clean Debian 11 installation on AMD64 CPU architecture.
# It will update OS, install neeeded packages, and preconfigure everything to run Nextcloud.
# There are Apache (web server), MariaDB (database server), PHP 8.1 (programming language), 
# NTP (time synchronization service), and Redis (cache server) used.
# Also new service for Nextcloud cron is generated that starts every 5 minutes.
#
# After install You may use Your web browser to access Nextcloud using local IP address.
# Both HTTP and HTTPS protocols are enabled by default (localhost certificate is generated).
#
# It was tested with Nextcloud v24.0.1.
#
# More info:
# [PL/ENG] https://www.marcinwilk.eu/projects/linux-scripts/nextcloud-debian-install/
#
# Feel free to contact me: marcin@marcinwilk.eu
# www.marcinwilk.eu
# Marcin Wilk
#
# License:
# 1. You use it at your own risk. Author is not responsible for any damage made with that script.
# 2. Any changes of scripts must be shared with author with authorization to implement them and share.
#
# V 1.0 - 20.06.2022
# - initial version based on private install script (for EL)

export LC_ALL=C
cpu=$( uname -m )
user=$( whoami )
debv=$( cat /etc/debian_version )
addr=$( hostname -I )
insl=/var/log/nextcloud-installer.log

echo -e "\e[38;5;214mNextcloud Debian 11 Install Script\e[39;0m
Version 1.0 for x86_64
by marcin@marcinwilk.eu - www.marcinwilk.eu"
echo "---------------------------------------------------------------------------"
if [ $user != root ]
then
    echo -e "You must be \e[38;5;214mroot\e[39;0m. Mission aborted!"
    echo -e "You are trying to start this script as: \e[1;31m$user\e[39;0m"
    exit 0
else
	echo "This script will install Nextcloud service."
	echo "Additional packages will be installed too:"
	echo "Apache, PHP 8.1, MariaDB and Let's encrypt."
fi

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
echo "Nextcloud installer for Debian 11 - v1.0 (www.marcinwilk.eu) started." >> $insl
date >> $insl
echo "---------------------------------------------------------------------------" >> $insl
# Generating passwords for database and SuperAdmin user.
openssl rand -base64 30 > /root/dbpass
openssl rand -base64 30 > /root/superadminpass
mp=$( cat /root/dbpass )
mp2=$( cat /root/superadminpass )

# timedatectl set-timezone Europe/Warsaw
echo "Updating OS."
apt-get update >> $insl && apt-get upgrade -y >> $insl && apt-get autoremove -y >> $insl
echo "Installing standard packages. It may take some time - be patient."
apt-get install -y git bzip2 unzip zip lsb-release locales-all rsync wget curl sed screen gawk mc sudo net-tools ethtool vim nano ufw apt-transport-https ca-certificates ntp >> $insl
# apt-get install -y task-polish
# localectl set-locale LANG=pl_PL.UTF-8
systemctl enable ntp >> $insl
systemctl restart ntp >> $insl

echo "Installing web server with PHP."
apt-get install -y apache2 apache2-utils >> $insl
wget -q -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg >> $insl
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list >> $insl
apt-get update >> $insl && apt-get upgrade -y >> $insl
apt-get install -y php libapache2-mod-php libmagickcore-6.q16-6-extra php8.1-mysql php8.1-common php8.1-redis php8.1-dom php8.1-curl php8.1-exif php8.1-fileinfo php8.1-bcmath php8.1-gmp php8.1-imagick php8.1-mbstring php8.1-xml php8.1-zip php8.1-iconv php8.1-intl php8.1-simplexml php8.1-xmlreader php8.1-ftp php8.1-ssh2 php8.1-sockets php8.1-gd php8.1-imap php8.1-soap php8.1-xmlrpc php8.1-apcu php8.1-dev php8.1-cli >> $insl
systemctl enable apache2 >> $insl
a2dissite 000-default >> $insl

echo "Setting up firewall"
ufw allow OpenSSH >> $insl
ufw allow 'WWW Full' >> $insl


# REDIS cache configure, adding socket for faster communication on local host
apt-get install -y redis-server >> $insl
sed -i '/# unixsocketperm 700/aunixsocketperm 777' /etc/redis/redis.conf
sed -i '/# unixsocketperm 700/aunixsocket /var/run/redis/redis.sock' /etc/redis/redis.conf
usermod -a -G redis www-data
systemctl restart redis >> $insl

#Best moment for VM Snapshot

## ffmpeg installing - used for generating thumbnails of video files
apt-get install -y ffmpeg >> $insl

#Enable APCu command line support
echo 'apc.enable_cli=1' >> /etc/php/8.1/cli/conf.d/20-apcu.ini

sed -i 's/\b128M\b/1024M/g' /etc/php/8.1/apache2/php.ini
sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 360/g' /etc/php/8.1/apache2/php.ini
sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' /etc/php/8.1/apache2/php.ini
sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' /etc/php/8.1/apache2/php.ini
sed -i 's/\bmax_input_time = 60\b/max_input_time = 280/g' /etc/php/8.1/apache2/php.ini
sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16884M/g' /etc/php/8.1/apache2/php.ini
sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16884M/g' /etc/php/8.1/apache2/php.ini
sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' /etc/php/8.1/apache2/php.ini
sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 360/g' /etc/php/8.1/apache2/php.ini
sed -i '/MySQLi]/amysqli.cache_size = 2000' /etc/php/8.1/apache2/php.ini

sed -i 's/\b128M\b/1024M/g' /etc/php/8.1/cli/php.ini
sed -i 's/\bmax_execution_time = 30\b/max_execution_time = 360/g' /etc/php/8.1/cli/php.ini
sed -i 's/\boutput_buffering = 4096\b/output_buffering = Off/g' /etc/php/8.1/cli/php.ini
sed -i 's/\bmax_input_vars = 1000\b/max_input_vars = 3000/g' /etc/php/8.1/cli/php.ini
sed -i 's/\bmax_input_time = 60\b/max_input_time = 280/g' /etc/php/8.1/cli/php.ini
sed -i 's/\bpost_max_size = 8M\b/post_max_size = 16884M/g' /etc/php/8.1/cli/php.ini
sed -i 's/\bupload_max_filesize = 2M\b/upload_max_filesize = 16884M/g' /etc/php/8.1/cli/php.ini
sed -i 's/\bmax_file_uploads = 20\b/max_file_uploads = 200/g' /etc/php/8.1/cli/php.ini
sed -i 's/\bdefault_socket_timeout = 20\b/default_socket_timeout = 360/g' /etc/php/8.1/cli/php.ini
sed -i '/MySQLi]/amysqli.cache_size = 2000' /etc/php/8.1/cli/php.ini

echo 'opcache.enable_cli=1' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
echo 'opcache.interned_strings_buffer=16' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
echo 'opcache.max_accelerated_files=10000' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
echo 'opcache.memory_consumption=128' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
echo 'opcache.save_comments=1' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini
echo 'opcache.revalidate_freq=1' >> /etc/php/8.1/apache2/conf.d/10-opcache.ini

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
a2ensite nextcloud.conf >> $insl

echo "Installing MariaDB database server."
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
mysql -e "GRANT ALL on nextdrive.* to nextcloud@localhost identified by '$mp'" >> $insl

# Make our changes take effect
mysql -e "FLUSH PRIVILEGES" >> $insl

# Importing data into database: enabling smb share in nextcloud, enabling plugins if needed.
# Export cmd: mysqldump -u root -p --all-databases --skip-lock-tables > alldb.sql

# Downloading and installing Let's encrypt mechanism
apt-get install -y python3-certbot-apache >> $insl

# Downloading and installing Nextcloud
mkdir /var/www/nextcloud
mkdir /var/www/nextcloud/data
wget -q https://download.nextcloud.com/server/releases/latest.tar.bz2 >> $insl
tar -xjf latest.tar.bz2 -C /var/www/ >> $insl
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
echo '  "adminpass"     => "Haslo.serwisoweX32*L",' >> /var/www/nextcloud/config/autoconfig.php
echo ');' >> /var/www/nextcloud/config/autoconfig.php

sudo -u www-data php8.1 /var/www/nextcloud/occ maintenance:install --database \
"mysql" --database-name "nextdrive"  --database-user "nextcloud" --database-pass \
"$mp" --admin-user "SuperAdmin" --admin-pass "$mp2" >> $insl

# Adding default language and locales to pl_PL and setting up email sending
#  'default_language' => 'pl',
#  'default_locale' => 'pl',

# sudo -u www-data php8.1 /var/www/nextcloud/occ config:system:set default_language --value="pl"
# sudo -u www-data php8.1 /var/www/nextcloud/occ config:system:set default_locale --value="pl"

# Enabling Redis in config file - default cache engine now
sed -i "/installed' => true,/a\ \ 'memcache.local' => '\\\OC\\\Memcache\\\Redis',\n\ \ 'filelocking.enabled' => true,\n \ 'memcache.locking' => '\\\OC\\\Memcache\\\Redis',\n \ 'memcache.distributed' => '\\\OC\\\Memcache\\\Redis',\n \ 'redis' =>\n \ array (\n \  \ 'host' => '/var/run/redis/redis.sock',\n \  \ 'port' => 0,\n \  \ 'dbindex' => 0,\n \  \ 'timeout' => 600.0,\n \ )," /var/www/nextcloud/config/config.php

# APCu cacheing
# sed -i "/installed' => true,/a\ \ 'memcache.local' => '\\\OC\\\Memcache\\\APCu'," /var/www/nextcloud/config/config.php

# Disabling info about creating free account on shared pages/links when logged out (because it is missleading for private nextcloud instances).
sed -i "/installed' => true,/a\ \ 'simpleSignUpLink.shown' => false," /var/www/nextcloud/config/config.php

# Command below should do nothing, but once in the past i needed that, so let it stay here...
sudo -u www-data php8.1 /var/www/nextcloud/occ db:add-missing-indices >> $insl

# Enabling plugins. Adding more trusted domains.
# Preparing list of local IP addresses to add.
hostname -I | xargs -n1 >> /root/ips.local

</root/ips.local awk '{print "sudo -u www-data php8.1 /var/www/nextcloud/occ config:system:set trusted_domains " NR " --value=\x22" $1 "\x22"}' | xargs -L 1 -0  | bash;
sudo -u www-data php8.1 /var/www/nextcloud/occ config:system:set trusted_domains 97 --value="127.0.0.1" >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ config:system:set trusted_domains 98 --value="nextdrive" >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ config:system:set trusted_domains 99 --value="nextcloud" >> $insl
# sudo -u www-data php8.1 /var/www/nextcloud/occ config:system:set default_phone_region --value="PL"
sudo -u www-data php8.1 /var/www/nextcloud/occ app:install contacts >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ app:install notes >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ app:install deck >> $insl
# sudo -u www-data php8.1 /var/www/nextcloud/occ app:install spreed >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ app:install calendar >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ app:install files_rightclick >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ app:disable updatenotification >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ app:install tasks >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ app:install groupfolders >> $insl

# Below lines will give more data if something goes wrong!
curl -I http://127.0.0.1/  >> $insl
cat /var/www/nextcloud/data/nextcloud.log >> $insl

# Disable .htaccess blocking because we use nginx that do not use it, also it should be handled by Nextcloud itself!
# sed -i "/CONFIG = array (/a\ \ 'blacklisted_files' => array()," /var/www/nextcloud/config/config.php

systemctl stop apache2
# Another lines that helped me in the past are here to stay...
sudo -u www-data php8.1 /var/www/nextcloud/occ maintenance:mode --on >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ db:convert-filecache-bigint --no-interaction >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ maintenance:mode --off >> $insl

# Preparing cron service to run cron.php every 5 minute
touch /etc/systemd/system/nextcloudcron.service
touch /etc/systemd/system/nextcloudcron.timer

echo '[Unit]' >> /etc/systemd/system/nextcloudcron.service
echo 'Description=Nextcloud cron.php job' >> /etc/systemd/system/nextcloudcron.service
echo '' >> /etc/systemd/system/nextcloudcron.service
echo '[Service]' >> /etc/systemd/system/nextcloudcron.service
echo 'User=www-data' >> /etc/systemd/system/nextcloudcron.service
echo 'ExecStart=php8.1 -f /var/www/nextcloud/cron.php' >> /etc/systemd/system/nextcloudcron.service
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
chmod 777 /var/www/nextcloud

sudo -u www-data php8.1 /var/www/nextcloud/occ maintenance:repair >> $insl

sudo -u www-data php8.1 /var/www/nextcloud/occ files:scan-app-data >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ files:scan  --all; >> $insl
sudo -u www-data php8.1 /var/www/nextcloud/occ files:cleanup; >> $insl
# sudo -u www-data php /var/www/nextcloud/occ preview:generate-all -vvv

# Finished!!!
echo ""
echo "Job done! Now make last steps in Your web browser!"
echo "Use # certbot if You want SSL"
echo ""
echo "You may access Your Nextcloud instalation using this address:
http://$addr or
https://$addr"
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
unset LC_ALL
exit 0


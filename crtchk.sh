#!/bin/bash

# This is script made for Pure-FTPd compatibility with Let's Encrypt.
# It search for difference between certificate currently used by pure-ftpd
# and Let's Encrypt. If there is one, then it recreate the correct file.
# 
###############################################################
#### Please do not delete crtchk.chk file after first use! ####
###############################################################
#
# More info:
# [PL] https://www.marcinwilk.eu/pl/projects/pure-ftpd-lets-encrypt/
# [EMG] https://www.marcinwilk.eu/en/projects/pure-ftpd-lets-encrypt/
#
# 06.07.2018
# Feel free to contact me: marcin@marcinwilk.eu
# www.marcinwilk.eu
# Marcin Wilk
#
# License:
# 1. You use it at your own risk. Author is not responsible for any damage made with that script.
# 2. Any changes of scripts must be shared with author with authorization to implement them and share.
#
##################################################
# Configuration lines, please apply your settings.
#
# Certificate used by pure-ftpd (default is /etc/ssl/private/pure-ftpd.pem - path with file).
crt=
#
# Letsencrypt certificate patch (default is /etc/letsencrypt/live/YOURDOMAIN - path only).
lecrt=/etc/letsencrypt/live/YOURDOMAIN
#
# Default directory for keeping chk file. (default is /opt/pure-ftpd-chk - path only)
chkdir=/opt/pure-ftpd-chk
#
# End of configuration.
##################################################

echo "--------------------------- -------------- - -----"
echo "Pure-FTPd Letsencrypt certificate creation script."
date
echo ""
echo "You must have Let's Encrypt installed and configured before using this!"
echo ""

if [ -z "${crt}" ]
then
    echo "Configuration is empty, please edit this file before use."
    exit 0
fi

echo "Looks like configuration is ready, let's work!"

if [ -e $chkdir/crtchk.chk ]
then
    echo "Check file has been found. Searching for differences."
    if diff $chkdir/crtchk.chk $lecrt/fullchain.pem > /dev/null
    then
      echo "Files are the same, no work to do now."
      exit 0
    else
      echo "Files are different. Creating new certificate for pure-ftpd."
      echo "------------------------------------- -------------- - -----" >> /var/log/pure-ftpd-crt.log
      echo "Files are different. Creating new certificate for pure-ftpd." >> /var/log/pure-ftpd-crt.log
      date >> /ver/log/pure-ftpd-crt.log
      rm $crt
      cat $lecrt/privkey.pem $lecrt/fullchain.pem > $crt
      rm $chkdir/crtchk.chk
      cp -L $lecrt/fullchain.pem $chkdir/crtchk.chk
    fi
else
    echo "No check file found. Possible first run. Creating one..."
    mkdir -p $chkdir
    cp -L $lecrt/fullchain.pem $chkdir/crtchk.chk
    echo "File has been created. Do not delete it."
    echo ""
    echo "Creating new certificate for pure-ftpd. If there is certificate file,"
    echo "it will be renamed into: $crt.old"
    if [ -e $crt ]
    then
    mv $crt $crt.old
    else
    echo "No file to be renamed."
    fi
    cat $lecrt/privkey.pem $lecrt/fullchain.pem > $crt
fi

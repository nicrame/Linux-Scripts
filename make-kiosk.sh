#!/bin/bash

# KIOSK generator for Scientific Linux and CentOS (versions 5; 6 and 7)
# Created using Scientific Linux
# Wasn't made and never tested on different distros than SL/CentOS/EL!
# Version 1.4 for i386 and x86_64
#
# More info:
# [PL] https://www.marcinwilk.eu/pl/projects/scientific-linux-and-centos-kiosk/
# [EMG] https://www.marcinwilk.eu/en/projects/scientific-linux-and-centos-kiosk/
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
# v 1.4 - 14.01.2016
# +Make browser history and setting reset every reboot 
# -and after user inactivity of 15 minutes
# -Use Chromium browser as main web browser in EL7
# +Add Matchbox Window Manager to handle fullscreen of browsers windows
# +Disable screen saver and blank screen
#
# v 1.3 - 12.01.2016
# Added SL/CentOS 7 support
#
# v 1.2 - 06.06.2014
# Added SL/CentOS 5 support (for older computers with low RAM)
#
# v 1.1 - 31.05.2014
# Not released, no changes in code, tested on EL6 and Fedora 20
#
# v 1.0 - 30.05.2014
# First release, tested on Scientific Linux 6 and CentOS 6
#
# Future plans:
# From now on there are no future plans (done in v 1.3)
# + Add support for 5.x tree (done in v 1.2)
# + Add support for 7.x tree (done in v 1.3)
#
# + Opera do not show license window (done in v 1.3)
# + Less controll on Opera browser by user (done in v 1.3)
# + Add flash support (done in v 1.2)
# + Add configuration options for users (first options in v 1.2)

############### Configuration

mainsite=http://google.com
#Site that will be loaded as default after KIOSK start.

cpu=$( uname -i )
# Change it to cpu=i386 or cpu=x86_64 to force it to work when you got
# non standard kernel or unknown CPU architecture.

log=/var/log/make-kiosk.log
# The directiry and file name where log output will be saved.
# You may specify any location because script run from root account.

user=$( whoami )
# User name that run the script. No reasons to change it.
# Used only for testing.

el5=$( cat /etc/redhat-release | grep "release 5" )
# Check if release version is 5. You may change it to el5=release 5
# so it will use options prepared for that versions.

el6=$( cat /etc/redhat-release | grep "release 6" )
el7=$( cat /etc/redhat-release | grep "release 7" )
# Same like above but checking for version 6 and 7.
# You may force to use instructions for all releases by setting
# them elX=release X in here. Where X is the EL version.

flash=yes
# Change it to flash=no, if you do not want to have flash installed.

############### End of configuration options

echo -e "Welcome in \e[93mKIOSK generator \e[39mfor Scientific Linux and CentOS."
echo -e "Version \e[91m1.4 \e[39msupporting EL/SL/CentOS version 5; 6 and 7."
echo ""
echo "This script will install additional software and will make changes"
echo "in system config files to make it work in KIOSK mode after reboot"
echo "with Opera started as web browser."
echo ""
echo "The log file will be created in /var/log/make-kiosk.log"
echo "Please attach this file for error reports."
echo ""
if [ $user != root ]
then
    echo "You must be root. Mission aborted!"
    echo "You are trying to start this script as: $user"
    echo "User $user didn't have root rights!" >> make-kiosk.log
    exit 0
else
    echo "Kernel processor architecture detected: $cpu"
fi
echo "------------------- ---------- -------- ----- -" >> $log
date >> $log
echo "Generating detected CPU & Kernel log."
cat /etc/*-release >> $log
uname -a >> $log
if [ -n "$el5" ]
then
echo "No lscpu in EL5, skipping CPU logging." >> $log
else
lscpu 1>> $log 2>> $log
fi
echo "This process will take some time, please be patient..."
if [ ! -f /etc/redhat-release ]
then
    echo "Your Linux distribution isn't supported by this script."
    echo "Mission aborted!"
    echo "Unsupported Linux distro!" >> $log
    exit 0
fi
if [ $cpu = x86_64 ]
then
    echo "Detected Kernel CPU arch. is x86_64!" >> $log
elif [ $cpu = i386 ]
then
    echo "Detected Kernel CPU arch. is i386!" >> $log
else
    echo "No supported kernel architecture. Aborting!" >> $log
    echo "I did not detected x86_64 or i386 kernel architecture."
    echo "It looks like your configuration isn't supported."
    echo "Mission aborted!"
    exit 0
fi

echo "Operation done in 5%"
echo "Adding user kiosk."
echo "Adding user kiosk." >> $log
useradd kiosk 1>> $log 2>> $log
echo "Installing wget."
echo "Installing wget." >> $log
yum -y install wget 1>> $log 2>> $log
echo "Operation done in 10%"
echo "Installing X Window system with GDM/Gnome/Matchbox. It will take very long!!! Be patient!!! Downloading up to ~300MB"
echo "Installing X Window system with GDM/Gnome/Matchbox." >> $log
yum -y groupinstall basic-desktop x11 fonts base-x 1>> $log 2>> $log
yum -y install gdm 1>> $log 2>> $log
if [ -n "$el5" ]
then
yum -y install make gawk gcc 1>> $log 2>> $log
yum -y install libX11-devel 1>> $log 2>> $log
yum -y install libXext-devel 1>> $log 2>> $log
cd /root/ 1>> $log 2>> $log
rm -f matchbox-window-manager-1.2.tar.gz 1>> $log 2>> $log
wget http://downloads.yoctoproject.org/releases/matchbox/matchbox-window-manager/1.2/matchbox-window-manager-1.2.tar.gz 1>> $log 2>> $log
tar xvf matchbox-window-manager-1.2.tar.gz 1>> $log 2>> $log
cd matchbox-window-manager-1.2 1>> $log 2>> $log
./configure --enable-standalone 1>> $log 2>> $log
make 1>> $log 2>> $log
make install 1>> $log 2>> $log
cd .. 1>> $log 2>> $log
else
yum -y install matchbox-window-manager 1>> $log 2>> $log
fi
yum -y install rsync 1>> $log 2>> $log
echo "Operation done in 60%"
echo "Checking EL version..."
if [ -n "$el5" ]
then
echo "EL 5.x detected, using older Opera version." >> $log
echo "EL 5.x detected, using older Opera version."
    if [ $cpu = x86_64 ]
    then
        echo "Downloading Opera for x86_64."
        rm -f opera-11.64-1403.x86_64.linux.tar 1>> $log 2>> $log
        wget http://get.geo.opera.com/pub/opera/linux/1164/opera-11.64-1403.x_86_64.linux.tar.bz2 1>> $log 2>> $log
        bzip2 -d opera-11.64-1403.x86_64.linux.tar.bz2 1>> $log 2>> $log
        tar xvf opera-11.64-1403.x86_64.linux.tar 1>> $log 2>> $log
        echo "Installing Opera."
        yum -y install cdparanoia-libs flac gstreamer gstreamer-plugins-base gstreamer-plugins-good gstreamer-tools libavc1394 libdv libiec61883 liboil libraw1394 libtheora speex 1>> $log 2>> $log
        opera-11.64-1403.x86_64.linux/install --unattended --system 1>> $log 2>> $log
        rm -rf opera-11.64-1403.x86_64.linux 1>> $log 2>> $log
        if [ $flash = yes ]
        then
    	    echo "Installing Flash." >> $log
    	    rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm 1>> $log 2>> $log
    	    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux 1>> $log 2>> $log
    	    yum -y check-update 1>> $log 2>> $log
    	    yum -y groupinstall sound-and-video 1>> $log 2>> $log
    	    yum -y install flash-plugin nspluginwrapper curl 1>> $log 2>> $log
    	else
    	    echo "Skipping flash install." >> $log
    	fi
    elif [ $cpu = i386 ]
    then
        echo "Downloading Opera for i386."
        rm -f opera-11.64-1403.i386.linux.tar 1>> $log 2>> $log
        wget http://get.geo.opera.com/pub/opera/linux/1164/opera-11.64-1403.i386.linux.tar.bz2 1>> $log 2>> $log
        bzip2 -d opera-11.64-1403.i386.linux.tar.bz2 1>> $log 2>> $log
        tar xvf opera-11.64-1403.i386.linux.tar 1>> $log 2>> $log
        echo "Installing Opera."
        yum -y install cdparanoia-libs flac gstreamer gstreamer-plugins-base gstreamer-plugins-good gstreamer-tools libavc1394 libdv libiec61883 liboil libraw1394 libtheora speex 1>> $log 2>> $log
        opera-11.64-1403.i386.linux/install --unattended --system 1>> $log 2>> $log
        rm -rf opera-11.64-1403.i386.linux 1>> $log 2>> $log
        if [ $flash = yes ]
        then
    	    echo "Installing Flash." >> $log
    	    rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-i386-1.0-1.noarch.rpm 1>> $log 2>> $log
    	    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux 1>> $log 2>> $log
    	    yum -y check-update 1>> $log 2>> $log
    	    yum -y groupinstall sound-and-video 1>> $log 2>> $log
    	    yum -y install flash-plugin nspluginwrapper curl 1>> $log 2>> $log
    	else
    	    echo "Skipping flash install." >> $log
    	fi
    else
        echo "No supported kernel architecture detected for Opera install. Mission aborted!"
        echo "Aborting Opera and Flash install, no x86_64 or i386!" >> $log
    fi
else
echo "EL 6/7 detected, using new Opera version." >> $log
echo "EL 6/7 detected, using new Opera version."
echo "Adding Xinit Session support." >> $log
echo "Adding Xinit Session support."
yum -y install gnome-session-xsession 1>> $log 2>> $log
yum -y install xorg-x11-xinit-session 1>> $log 2>> $log
    if [ -n "$el6" ]
    then
    echo "EL 6.x detected, using correct Opera version." >> $log
        if [ $cpu = x86_64 ]
        then
	    echo "Downloading Opera for x86_64."
    	    rm -f opera-12.16-1860.x86_64.rpm 1>> $log 2>> $log
    	    wget http://get.geo.opera.com/pub/opera/linux/1216/opera-12.16-1860.x86_64.rpm 1>> $log 2>> $log
	    echo "Installing Opera."
            yum -y localinstall opera-12.16*.rpm 1>> $log 2>> $log
        if [ $flash = yes ]
        then
    	    echo "Installing Flash." >> $log
    	    rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm 1>> $log 2>> $log
    	    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux 1>> $log 2>> $log
    	    yum -y check-update 1>> $log 2>> $log
    	    yum -y install flash-plugin nspluginwrapper alsa-plugins-pulseaudio libcurl 1>> $log 2>> $log
    	else
    	    echo "Skipping flash install." >> $log
    	fi
	elif [ $cpu = i386 ]
	then
    	    echo "Downloading Opera for i386."
    	    rm -f opera-12.16-1860.i386.rpm 1>> $log 2>> $log
    	    wget http://get.geo.opera.com/pub/opera/linux/1216/opera-12.16-1860.i386.rpm 1>> $log 2>> $log
    	    echo "Installing Opera."
    	    yum -y localinstall opera-12.16*.rpm 1>> $log 2>> $log
        if [ $flash = yes ]
        then
    	    echo "Installing Flash." >> $log
    	    rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-i386-1.0-1.noarch.rpm 1>> $log 2>> $log
    	    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux 1>> $log 2>> $log
    	    yum -y check-update 1>> $log 2>> $log
    	    yum -y install flash-plugin nspluginwrapper alsa-plugins-pulseaudio libcurl 1>> $log 2>> $log
    	else
    	    echo "Skipping flash install." >> $log
    	fi
	else
    	    echo "No supported kernel architecture detected for Opera install. Mission aborted!"
    	    echo "Aborting Opera install, no x86_64 or i386!" >> $log
	fi
    fi
    if [ -n "$el7" ]
    then
    echo "EL 7.x detected, using correct Opera version." >> $log
        if [ $cpu = x86_64 ]
        then
            echo "Downloading Opera for x86_64."
            rm -f opera-12.16-1860.x86_64.rpm 1>> $log 2>> $log
            wget http://get.geo.opera.com/pub/opera/linux/1216/opera-12.16-1860.x86_64.rpm 1>> $log 2>> $log
            echo "Installing Opera."
            yum -y localinstall opera-12.16*.rpm 1>> $log 2>> $log
        if [ $flash = yes ]
        then
    	    echo "Installing Flash." >> $log
    	    rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm 1>> $log 2>> $log
    	    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux 1>> $log 2>> $log
    	    yum -y check-update 1>> $log 2>> $log
    	    yum -y install flash-plugin nspluginwrapper alsa-plugins-pulseaudio libcurl 1>> $log 2>> $log
        else
    	    echo "Skipping flash install." >> $log
        fi
        elif [ $cpu = i386 ]
        then
    	    echo "Downloading Opera for i386."
    	    rm -f opera-12.16-1860.i386.rpm 1>> $log 2>> $log
    	    wget http://get.geo.opera.com/pub/opera/linux/1216/opera-12.16-1860.i386.rpm 1>> $log 2>> $log
    	    echo "Installing Opera."
    	    yum -y localinstall opera-12.16*.rpm 1>> $log 2>> $log
        if [ $flash = yes ]
        then
            echo "Installing Flash." >> $log
            rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-i386-1.0-1.noarch.rpm 1>> $log 2>> $log
            rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux 1>> $log 2>> $log
            yum -y check-update 1>> $log 2>> $log
            yum -y install flash-plugin nspluginwrapper alsa-plugins-pulseaudio libcurl 1>> $log 2>> $log
        else
            echo "Skipping flash install." >> $log
            fi
        else
            echo "No supported kernel architecture detected for Opera install. Mission aborted!"
            echo "Aborting Opera install, no x86_64 or i386!" >> $log
        fi
    fi
fi
echo "Operation done in 85%"
echo "Configuring login manager (GDM), adding lines for autologin kiosk user."
autologin=$( cat /etc/gdm/custom.conf | grep AutomaticLoginEnable=true )
loginname=$( cat /etc/gdm/custom.conf | grep AutomaticLogin=kiosk )
if [ -n "$autologin" ]
then
    echo "File is already configured for automatic login."
    echo "Current automatic login config:"
    grep AutomaticLoginEnable /etc/gdm/custom.conf
    echo ""
    echo "Check the GDM file /etc/gdm/custom.conf."
    echo "Aborting adding AutomaticLoginEnable=true!" >> $log
    cat /etc/gdm/custom.conf 1>> $log 2>> $log
else
    echo "Adding line to /etc/gdm/custom.conf for automatic login."
    echo "Adding line to /etc/gdm/custom.conf for automatic login." >> $log
    sed -i '/daemon]/aAutomaticLoginEnable=true' /etc/gdm/custom.conf 1>> $log 2>> $log
fi
if [ -n "$loginname" ]
then
    echo "File is already configured for user kiosk to autologin."
    echo "Aborting adding AutomaticLogin=kiosk!" >> $log
    grep AutomaticLogin /etc/gdm/custom.conf 1>> $log 2>> $log
else
    echo "Adding line to /etc/gdm/custom.conf for login user name."
    echo "Adding line to /etc/gdm/custom.conf for login user name." >> $log
    sed -i '/AutomaticLoginEnable=true/aAutomaticLogin=kiosk' /etc/gdm/custom.conf 1>> $log 2>> $log
fi
if [ -n "$el7" ]
then
    echo "Adding line to /etc/gdm/custom.conf for default X Session in EL7." >> $log
    echo "And creating session file for specific user in /var/lib/AccountsService/users/kiosk." >> $log
    sed -i '/AutomaticLogin=kiosk/aDefaultSession=xinit-compat.desktop' /etc/gdm/custom.conf 1>> $log 2>> $log
    touch /var/lib/AccountsService/users/kiosk
    chmod 644 /var/lib/AccountsService/users/kiosk
    echo "[User]" >> /var/lib/AccountsService/users/kiosk
    echo "Language=" >> /var/lib/AccountsService/users/kiosk
    echo "XSession=xinit-compat" >> /var/lib/AccountsService/users/kiosk
    echo "SystemAccount=false" >> /var/lib/AccountsService/users/kiosk
else
    echo "No need for default session in gdm.conf." >> $log
fi
echo "Operation done in 90%"
echo "Configuring system to start in graphical mode."
echo "Configuring system to start in graphical mode." >> $log
if [ -n "$el7" ]
then
echo "Current starting mode in EL7 (text or graphical is:" >> $log
systemctl get-default 1>> $log 2>> $log
echo "Setting up graphical boot in EL7." >> $log
systemctl set-default graphical.target 1>> $log 2>> $log
else
    gfxboot=$( cat /etc/inittab | grep id:5:initdefault: )
    if [ -n "$gfxboot" ]
    then
	echo "System is already configured for graphical boot."
	echo "Aborting configuring graphical boot. Already enabled!" >> $log
    else
	echo "Parsing /etc/inittab for graphical boot."
	echo "Parsing /etc/inittab for graphical boot." >> $log
        sed -i 's/id:1:initdefault:/id:5:initdefault:/g' /etc/inittab 1>> $log 2>> $log
        sed -i 's/id:2:initdefault:/id:5:initdefault:/g' /etc/inittab 1>> $log 2>> $log
        sed -i 's/id:3:initdefault:/id:5:initdefault:/g' /etc/inittab 1>> $log 2>> $log
        sed -i 's/id:4:initdefault:/id:5:initdefault:/g' /etc/inittab 1>> $log 2>> $log
    fi
fi
echo "Operation done in 93%"
echo "Disabling firstboot."
echo "Disabling firstboot." >> $log
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot
echo "Operation done in 94%"
if [ -n "$el5" ]
then
echo "Skipping .dmrc creation in current distribution version."
echo "Generating Opera 11 browser startup config file."
echo "Generating Opera 11 browser startup config file." >> $log
echo "xset s off" > /home/kiosk/.xsession
echo "xset -dpms" >> /home/kiosk/.xsession
echo "matchbox-window-manager &" >> /home/kiosk/.xsession
echo "while true; do" >> /home/kiosk/.xsession
echo "rsync -qr --delete --exclude='.Xauthority' /opt/kiosk/ /home/kiosk/" >> /home/kiosk/.xsession
echo "opera -nomail -noprint -noexit -nochangebuttons -nosave -nodownload -nomaillinks -nomenu -nominmaxbuttons -nocontextmenu -resetonexit -nosession $mainsite" >> /home/kiosk/.xsession
echo "done" >> /home/kiosk/.xsession
mkdir /home/kiosk/.opera
touch /home/kiosk/.opera/operaprefs.ini
echo "[State]" > /home/kiosk/.opera/operaprefs.ini
echo "Accept License=1" >> /home/kiosk/.opera/operaprefs.ini
chown kiosk:kiosk /home/kiosk/.opera 1>> $log 2>> $log
chown kiosk:kiosk /home/kiosk/.opera/operaprefs.ini 1>> $log 2>> $log
chmod +x /home/kiosk/.xsession 1>> $log 2>> $log
chown kiosk:kiosk /home/kiosk/.xsession 1>> $log 2>> $log
else
echo "Generating Opera 12 browser startup config file."
echo "Generating Opera 12 browser startup config file." >> $log
echo "xset s off" > /home/kiosk/.xsession
echo "xset -dpms" >> /home/kiosk/.xsession
echo "matchbox-window-manager &" >> /home/kiosk/.xsession
echo "while true; do" >> /home/kiosk/.xsession
echo "rsync -qr --delete --exclude='.Xauthority' /opt/kiosk/ $HOME/" >> /home/kiosk/.xsession
echo "opera -k -nomail -noprint -noexit -nochangebuttons -nosave -nodownload -nomaillinks -nomenu -nominmaxbuttons -nocontextmenu -resetonexit -nosession $mainsite" >> /home/kiosk/.xsession
echo "done" >> /home/kiosk/.xsession
mkdir /home/kiosk/.opera
touch /home/kiosk/.opera/operaprefs.ini
echo "[State]" >> /home/kiosk/.opera/operaprefs.ini
echo "Accept License=1" >> /home/kiosk/.opera/operaprefs.ini
chown kiosk:kiosk /home/kiosk/.opera 1>> $log 2>> $log
chown kiosk:kiosk /home/kiosk/.opera/operaprefs.ini 1>> $log 2>> $log
chmod +x /home/kiosk/.xsession 1>> $log 2>> $log
ln -s /home/kiosk/.xsession /home/kiosk/.xinitrc
chown kiosk:kiosk /home/kiosk/.xsession 1>> $log 2>> $log
echo "Creating desktop profile session file."
echo "Creating .dmrc desktop profile session file." >> $log
echo "[Desktop]" > /home/kiosk/.dmrc
echo "Session=xinit-compat" >> /home/kiosk/.dmrc
echo "Language=$LANG" >> /home/kiosk/.dmrc
chown kiosk:kiosk /home/kiosk/.dmrc 1>> $log 2>> $log
fi
echo "Operation done in 96%"
echo "Copying files for reseting every user restart." >> $log
echo "Copying files for reseting every user restart."
cp -r /home/kiosk /opt/
chmod 755 /opt/kiosk
chown kiosk:kiosk -R /opt/kiosk
echo "Operation done in 100%"
echo "Mission completed!"
echo ""
echo "If You got any comments or questions: marcin@marcinwilk.eu"
echo "Remember that after reboot it should start directly in KIOSK."
echo -e "\e[92mUse \e[93mCTRL+ALT+F2 \e[92mto go to console in KIOSK mode!!!"
echo -e "\e[39mThank You."
echo "Marcin Wilk"
echo "Job done!" >> $log
sleep 6
